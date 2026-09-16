"""Batch updater for the Helm charts packaged by internal/fetchhelm.nix.

Resolves every chart's newest version from one repository index (or OCI tag list)
per upstream, then downloads and rewrites only the charts that actually moved.
"""

import concurrent.futures
import dataclasses
import difflib
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.request

import click
import yaml

CACERT_PATH = "@cacert@"
CRANE_PATH = "@crane@"
GH_PATH = "@gh@"
GIT_PATH = "@git@"
HELM_PATH = "@helm@"
NIX_HASH_PATH = "@nix-hash@"
NIX_PATH = "@nix@"

STORE_PREFIX = re.compile(r"^/nix/store/[^/]+/")

USER_AGENT = "update-helm-charts"

SEMVER = re.compile(
    r"^v?(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$"
)

DISCOVER_EXPR = """
ps:
builtins.listToAttrs (
  map (n: {
    name = n;
    value = ps.${n}.helmChart;
  }) (builtins.filter (n: ps.${n} ? helmChart) (builtins.attrNames ps))
)
"""


class ChartError(Exception):
    """A failure scoped to a single chart; never aborts the whole run."""


@dataclasses.dataclass
class Chart:
    attr: str
    pname: str
    url: str
    chart: str
    version: str
    hash: str
    file: str
    version_line: int
    hash_line: int

    @property
    def is_oci(self) -> bool:
        return self.url.startswith("oci://")


@dataclasses.dataclass
class Result:
    chart: Chart
    status: str
    latest: str | None = None
    message: str = ""


def log(message: str) -> None:
    print(message, file=sys.stderr)


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    log(f"+ {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True, check=False, **kwargs)
    if result.returncode != 0 and result.stderr:
        log(result.stderr.rstrip())
    result.check_returncode()
    return result


def parse_version(raw: str) -> tuple[tuple[int, int, int], str | None] | None:
    m = SEMVER.match(raw)
    if not m:
        return None
    major, minor, patch, pre = m.groups()
    return (int(major), int(minor or 0), int(patch or 0)), pre


def prerelease_key(pre: str | None) -> tuple:
    """Semver prerelease precedence: numeric identifiers sort below alphanumeric."""
    if pre is None:
        return ()
    out = []
    for ident in pre.split("."):
        if ident.isdigit():
            out.append((0, int(ident), ""))
        else:
            out.append((1, 0, ident))
    return tuple(out)


def sort_key(parsed: tuple[tuple[int, int, int], str | None]) -> tuple:
    nums, pre = parsed
    return nums, 1 if pre is None else 0, prerelease_key(pre)


def strip_v(raw: str) -> str:
    return raw.removeprefix("v")


def select_version(candidates: list[str], current: str) -> str | None:
    """Newest candidate by semver precedence, skipping anything unparseable."""
    current_parsed = parse_version(current)
    allow_prerelease = current_parsed is not None and current_parsed[1] is not None

    parsed = [(raw, parse_version(raw)) for raw in candidates]
    valid = [(raw, p) for raw, p in parsed if p is not None]
    if not allow_prerelease:
        valid = [(raw, p) for raw, p in valid if p[1] is None]
    if not valid:
        return None
    return max(valid, key=lambda item: sort_key(item[1]))[0]


def repo_relative(position: str, repo_root: str) -> str:
    """Map a chart's meta position back to a path inside the working tree."""
    if position.startswith(repo_root + "/"):
        return position[len(repo_root) + 1 :]
    stripped = STORE_PREFIX.sub("", position)
    if stripped == position:
        raise ChartError(f"cannot map {position!r} into {repo_root!r}")
    return stripped


def current_system() -> str:
    cmd = [NIX_PATH, "eval", "--raw", "--impure", "--expr", "builtins.currentSystem"]
    return run(cmd).stdout.strip()


def discover(repo_root: str) -> list[Chart]:
    cmd = [
        NIX_PATH,
        "eval",
        "--json",
        f"{repo_root}#packages.{current_system()}",
        "--apply",
        DISCOVER_EXPR,
    ]
    data = json.loads(run(cmd).stdout)
    return [
        Chart(
            attr=attr,
            pname=info["pname"],
            url=info["url"],
            chart=info["chart"],
            version=info["version"],
            hash=info["hash"],
            file=repo_relative(info["file"], repo_root),
            version_line=info["versionLine"],
            hash_line=info["hashLine"],
        )
        for attr, info in sorted(data.items())
    ]


def fetch_index(url: str) -> dict[str, list[str]]:
    """Every chart name in a Helm repository mapped to its published versions."""
    index_url = url.rstrip("/") + "/index.yaml"
    log(f"+ fetch {index_url}")
    request = urllib.request.Request(index_url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        raw = response.read()
    loader = getattr(yaml, "CSafeLoader", yaml.SafeLoader)
    entries = (yaml.load(raw, Loader=loader) or {}).get("entries") or {}
    return {
        name: [str(e["version"]) for e in versions if "version" in e]
        for name, versions in entries.items()
    }


def fetch_oci_tags(url: str) -> list[str]:
    """Tags for an OCI chart. crane handles registry auth and tag pagination."""
    result = run([CRANE_PATH, "ls", url[len("oci://") :]])
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def resolve_latest(charts: list[Chart], jobs: int) -> dict[str, tuple[str | None, str]]:
    """Map each chart attr to (latest version, error message)."""
    sources: dict[str, object] = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        futures = {}
        for url in sorted({c.url for c in charts}):
            fetch = fetch_oci_tags if url.startswith("oci://") else fetch_index
            futures[pool.submit(fetch, url)] = url
        for future, url in futures.items():
            try:
                sources[url] = future.result()
            except (OSError, subprocess.CalledProcessError, yaml.YAMLError) as err:
                sources[url] = err

    resolved: dict[str, tuple[str | None, str]] = {}
    for chart in charts:
        source = sources[chart.url]
        if isinstance(source, Exception):
            resolved[chart.attr] = (None, str(source))
            continue
        if chart.is_oci:
            candidates = source
        else:
            candidates = source.get(chart.chart)
            if candidates is None:
                resolved[chart.attr] = (None, f"{chart.chart} not published in index")
                continue
        latest = select_version(candidates, chart.version)
        resolved[chart.attr] = (
            (latest, "") if latest else (None, "no usable version published")
        )
    return resolved


def classify(chart: Chart, latest: str | None, error: str) -> Result:
    if error:
        return Result(chart, "error", None, error)
    new = strip_v(latest)
    if new == chart.version:
        return Result(chart, "up-to-date", new)
    old_parsed = parse_version(chart.version)
    new_parsed = parse_version(new)
    if old_parsed is None or new_parsed is None:
        return Result(chart, "skipped", new, "unparseable version")
    if sort_key(new_parsed) < sort_key(old_parsed):
        return Result(chart, "skipped", new, "refusing downgrade")
    return Result(chart, "update", new)


def helm_pull(chart: Chart, version: str, tmpdir: str) -> str:
    out_dir = os.path.join(tmpdir, "out")
    os.makedirs(out_dir, exist_ok=True)
    cmd = [HELM_PATH, "pull"]
    if chart.is_oci:
        cmd += [chart.url]
    else:
        cmd += [chart.chart, "--repo", chart.url]
    run(
        cmd + ["--version", version, "--destination", out_dir, "--untar"],
        env={
            **os.environ,
            "HELM_CACHE_HOME": os.path.join(tmpdir, ".cache"),
            "HELM_CONFIG_HOME": os.path.join(tmpdir, ".config"),
            "HELM_DATA_HOME": os.path.join(tmpdir, ".data"),
        },
    )
    subdirs = [
        d for d in os.listdir(out_dir) if os.path.isdir(os.path.join(out_dir, d))
    ]
    if len(subdirs) != 1:
        raise ChartError(f"expected exactly one chart directory, found {subdirs}")
    return os.path.join(out_dir, subdirs[0])


def chart_yaml_version(chart_path: str) -> str:
    """Read Chart.yaml's version as text; YAML would coerce 1.20 to the float 1.2."""
    with open(os.path.join(chart_path, "Chart.yaml"), "r") as f:
        for line in f:
            m = re.match(r'^version:\s*"?([^"\s]+)"?\s*$', line)
            if m:
                return strip_v(m.group(1))
    raise ChartError("no version field in Chart.yaml")


def nix_hash(path: str) -> str:
    return run([NIX_HASH_PATH, "--type", "sha256", "--sri", path]).stdout.strip()


def rewrite(content: str, line_no: int, key: str, old: str, new: str) -> str:
    """Replace one known line, refusing to touch anything that looks unexpected."""
    lines = content.split("\n")
    index = line_no - 1
    if index < 0 or index >= len(lines):
        raise ChartError(f"line {line_no} out of range")
    line = lines[index]
    if f'{key} = "{old}"' not in line:
        raise ChartError(f'line {line_no} is not {key} = "{old}"; got: {line.strip()}')
    lines[index] = line.replace(f'"{old}"', f'"{new}"', 1)
    return "\n".join(lines)


def git(*args: str) -> str:
    return run([GIT_PATH, *args]).stdout.strip()


def gh(*args: str) -> str:
    return run([GH_PATH, *args]).stdout.strip()


def apply_chart(chart: Chart, new_version: str, opts: dict) -> Result:
    with tempfile.TemporaryDirectory() as tmpdir:
        chart_path = helm_pull(chart, new_version, tmpdir)
        published = chart_yaml_version(chart_path)
        if published != new_version:
            raise ChartError(f"pulled {published} but expected {new_version}")
        new_hash = nix_hash(chart_path)

    with open(chart.file, "r") as f:
        original = f.read()

    content = rewrite(
        original, chart.version_line, "version", chart.version, new_version
    )
    content = rewrite(content, chart.hash_line, "hash", chart.hash, new_hash)

    message = f"{chart.pname}: {chart.version} -> {new_version}"

    if opts["dry_run"]:
        sys.stdout.writelines(
            difflib.unified_diff(
                original.splitlines(keepends=True),
                content.splitlines(keepends=True),
                fromfile=chart.file,
                tofile=chart.file,
            )
        )
        return Result(chart, "update", new_version, message)

    with open(chart.file, "w") as f:
        f.write(content)

    if not opts["commit"]:
        return Result(chart, "updated", new_version, message)

    git("add", "--", chart.file)
    git("commit", "--message", message)

    if not opts["push"]:
        return Result(chart, "committed", new_version, message)

    branch = f"update-{chart.attr}"
    git("push", "--force", "origin", f"HEAD:refs/heads/{branch}")
    if gh("pr", "list", "--head", branch, "--json", "url", "--jq", "length") == "0":
        gh(
            "pr",
            "create",
            "--base",
            "main",
            "--head",
            branch,
            "--title",
            f"Update {chart.attr}",
            "--body",
            message,
        )
    gh("pr", "merge", "--merge", "--auto", branch)
    return Result(chart, "opened", new_version, message)


def report(results: list[Result]) -> None:
    width = max((len(r.chart.attr) for r in results), default=10)
    for r in sorted(results, key=lambda r: (r.status, r.chart.attr)):
        note = ""
        if r.message and r.status in ("error", "skipped"):
            note = f"  ({r.message.splitlines()[0]})"
        log(
            f"{r.chart.attr:<{width}}  {r.chart.version:>12} -> "
            f"{r.latest or '-':<12} {r.status}{note}"
        )
    counts: dict[str, int] = {}
    for r in results:
        counts[r.status] = counts.get(r.status, 0) + 1
    log(", ".join(f"{n} {status}" for status, n in sorted(counts.items())))


def write_github_summary(results: list[Result]) -> None:
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not path:
        return
    rows = ["| chart | current | latest | status |", "| --- | --- | --- | --- |"]
    for r in sorted(results, key=lambda r: (r.status, r.chart.attr)):
        rows.append(
            f"| {r.chart.attr} | {r.chart.version} | {r.latest or '-'} | {r.status} |"
        )
    with open(path, "a") as f:
        f.write("## Helm charts\n\n" + "\n".join(rows) + "\n")


@click.command()
@click.option("--repo-root", default=os.getcwd, help="Working tree to update.")
@click.option("--only", multiple=True, help="Limit to these attributes.")
@click.option("--jobs", default=8, show_default=True, help="Parallel version lookups.")
@click.option("--dry-run", is_flag=True, help="Print the diff instead of applying it.")
@click.option("--commit", is_flag=True, help="Commit each chart. Implies writing.")
@click.option("--push", is_flag=True, help="Push and open PRs. Implies --commit.")
@click.option("--write", is_flag=True, help="Edit files without committing.")
@click.option("--json", "as_json", is_flag=True, help="Emit results as JSON.")
@click.option("--summary", is_flag=True, help="Append to $GITHUB_STEP_SUMMARY.")
def main(repo_root, only, jobs, dry_run, commit, push, write, as_json, summary):
    """Update pinned Helm chart versions and hashes.

    With no flags this only reports what is outdated: one nix eval plus one
    version lookup per upstream repository, downloading no charts.
    """
    os.environ.setdefault("SSL_CERT_FILE", CACERT_PATH)
    repo_root = os.path.abspath(repo_root)
    os.chdir(repo_root)

    commit = commit or push
    mutate = dry_run or write or commit

    charts = discover(repo_root)
    if only:
        charts = [c for c in charts if c.attr in set(only)]
    log(f"discovered {len(charts)} charts")

    resolved = resolve_latest(charts, jobs)
    results = [classify(c, *resolved[c.attr]) for c in charts]

    if mutate:
        base = git("rev-parse", "HEAD") if push else None
        applied = []
        for result in results:
            if result.status != "update":
                applied.append(result)
                continue
            try:
                applied.append(
                    apply_chart(
                        result.chart,
                        result.latest,
                        {"dry_run": dry_run, "commit": commit, "push": push},
                    )
                )
            except (ChartError, subprocess.CalledProcessError, OSError) as err:
                applied.append(Result(result.chart, "error", result.latest, str(err)))
            finally:
                if push and base:
                    git("reset", "--hard", base)
        results = applied

    if as_json:
        print(
            json.dumps(
                [
                    {
                        "attr": r.chart.attr,
                        "current": r.chart.version,
                        "latest": r.latest,
                        "status": r.status,
                        "message": r.message,
                    }
                    for r in results
                ],
                indent=2,
            )
        )
    else:
        report(results)

    if summary:
        write_github_summary(results)

    if any(r.status == "error" for r in results):
        sys.exit(1)


if __name__ == "__main__":
    main()
