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

SEMVER = re.compile(
    r"^v?(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$"
)

DISCOVER_EXPR = """
let
  ps = (builtins.getFlake "@root@").packages.${builtins.currentSystem};
in
builtins.listToAttrs (
  map (n: {
    name = n;
    value = ps.${n}.helmChart;
  }) (builtins.filter (n: ps.${n} ? helmChart) (builtins.attrNames ps))
)
"""


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


def parse_version(raw: str) -> tuple[tuple[int, int, int], bool] | None:
    m = SEMVER.match(raw)
    if not m:
        return None
    major, minor, patch, pre = m.groups()
    return (int(major), int(minor or 0), int(patch or 0)), pre is None


def select_version(candidates: list[str], current: str) -> str | None:
    current_parsed = parse_version(current)
    allow_prerelease = current_parsed is not None and not current_parsed[1]

    parsed = [(raw, parse_version(raw)) for raw in candidates]
    valid = [(raw, p) for raw, p in parsed if p is not None]
    if not allow_prerelease:
        valid = [(raw, p) for raw, p in valid if p[1]]
    if not valid:
        return None
    return max(valid, key=lambda item: item[1])[0]


def discover(repo_root: str) -> list[Chart]:
    cmd = [
        NIX_PATH,
        "eval",
        "--json",
        "--impure",
        "--expr",
        DISCOVER_EXPR.replace("@root@", repo_root),
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
            file=STORE_PREFIX.sub("", info["file"]),
            version_line=info["versionLine"],
            hash_line=info["hashLine"],
        )
        for attr, info in sorted(data.items())
    ]


def fetch_index(url: str) -> dict[str, list[str]]:
    index_url = url.rstrip("/") + "/index.yaml"
    log(f"+ fetch {index_url}")
    request = urllib.request.Request(
        index_url, headers={"User-Agent": "update-helm-charts"}
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        raw = response.read()
    loader = getattr(yaml, "CSafeLoader", yaml.SafeLoader)
    entries = (yaml.load(raw, Loader=loader) or {}).get("entries") or {}
    return {
        name: [str(e["version"]) for e in versions if "version" in e]
        for name, versions in entries.items()
    }


def fetch_oci_tags(url: str) -> list[str]:
    result = run([CRANE_PATH, "ls", url[len("oci://") :]])
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def resolve_latest(charts: list[Chart]) -> list[Result]:
    sources: dict[str, object] = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        futures = {}
        for url in sorted({c.url for c in charts}):
            fetch = fetch_oci_tags if url.startswith("oci://") else fetch_index
            futures[pool.submit(fetch, url)] = url
        for future, url in futures.items():
            try:
                sources[url] = future.result()
            except (OSError, subprocess.CalledProcessError, yaml.YAMLError) as err:
                sources[url] = err

    results = []
    for chart in charts:
        source = sources[chart.url]
        if isinstance(source, Exception):
            results.append(Result(chart, "error", None, str(source)))
            continue
        candidates = source if chart.is_oci else source.get(chart.chart)
        if candidates is None:
            results.append(
                Result(chart, "error", None, f"{chart.chart} not published in index")
            )
            continue
        latest = select_version(candidates, chart.version)
        if latest is None:
            results.append(Result(chart, "error", None, "no usable version published"))
            continue
        results.append(classify(chart, latest))
    return results


def classify(chart: Chart, latest: str) -> Result:
    new = latest.removeprefix("v")
    if new == chart.version:
        return Result(chart, "up-to-date", new)
    old_parsed = parse_version(chart.version)
    if old_parsed is None:
        return Result(chart, "skipped", new, "unparseable pinned version")
    if parse_version(new) < old_parsed:
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
        raise ValueError(f"expected exactly one chart directory, found {subdirs}")
    return os.path.join(out_dir, subdirs[0])


def chart_yaml_version(chart_path: str) -> str:
    with open(os.path.join(chart_path, "Chart.yaml"), "r") as f:
        for line in f:
            m = re.match(r'^version:\s*"?([^"\s]+)"?\s*$', line)
            if m:
                return m.group(1).removeprefix("v")
    raise ValueError("no version field in Chart.yaml")


def nix_hash(path: str) -> str:
    return run([NIX_HASH_PATH, "--type", "sha256", "--sri", path]).stdout.strip()


def rewrite(content: str, line_no: int, key: str, old: str, new: str) -> str:
    lines = content.split("\n")
    index = line_no - 1
    if index < 0 or index >= len(lines):
        raise ValueError(f"line {line_no} out of range")
    line = lines[index]
    if f'{key} = "{old}"' not in line:
        raise ValueError(f'line {line_no} is not {key} = "{old}"; got: {line.strip()}')
    lines[index] = line.replace(f'"{old}"', f'"{new}"', 1)
    return "\n".join(lines)


def git(*args: str) -> str:
    return run([GIT_PATH, *args]).stdout.strip()


def gh(*args: str) -> str:
    return run([GH_PATH, *args]).stdout.strip()


def apply_chart(chart: Chart, new_version: str, dry_run: bool, push: bool) -> Result:
    with tempfile.TemporaryDirectory() as tmpdir:
        chart_path = helm_pull(chart, new_version, tmpdir)
        published = chart_yaml_version(chart_path)
        if published != new_version:
            raise ValueError(f"pulled {published} but expected {new_version}")
        new_hash = nix_hash(chart_path)

    with open(chart.file, "r") as f:
        original = f.read()

    content = rewrite(
        original, chart.version_line, "version", chart.version, new_version
    )
    content = rewrite(content, chart.hash_line, "hash", chart.hash, new_hash)

    message = f"{chart.pname}: {chart.version} -> {new_version}"

    if dry_run:
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

    if not push:
        return Result(chart, "updated", new_version, message)

    git("add", "--", chart.file)
    git("commit", "--message", message, "--", chart.file)

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
    changed = [r for r in results if r.status != "up-to-date"]
    if not path or not changed:
        return
    rows = ["| chart | current | latest | status |", "| --- | --- | --- | --- |"]
    for r in sorted(changed, key=lambda r: (r.status, r.chart.attr)):
        rows.append(
            f"| {r.chart.attr} | {r.chart.version} | {r.latest or '-'} | {r.status} |"
        )
    with open(path, "a") as f:
        f.write("\n".join(rows) + "\n")


@click.command()
@click.option("--only", multiple=True, help="Limit to these attributes.")
@click.option("--dry-run", is_flag=True, help="Print the diff instead of applying it.")
@click.option("--push", is_flag=True, help="Commit, push, and open one PR per chart.")
@click.option("--write", is_flag=True, help="Edit files without committing.")
def main(only, dry_run, push, write):
    os.environ.setdefault("SSL_CERT_FILE", CACERT_PATH)

    charts = discover(os.getcwd())
    if only:
        charts = [c for c in charts if c.attr in set(only)]
    log(f"discovered {len(charts)} charts")

    results = resolve_latest(charts)

    if dry_run or write or push:
        base = git("rev-parse", "HEAD") if push else None
        applied = []
        for result in results:
            if result.status != "update":
                applied.append(result)
                continue
            try:
                applied.append(apply_chart(result.chart, result.latest, dry_run, push))
            except (ValueError, subprocess.CalledProcessError, OSError) as err:
                applied.append(Result(result.chart, "error", result.latest, str(err)))
            finally:
                if push and base:
                    git("reset", "--hard", base)
        results = applied

    report(results)
    write_github_summary(results)

    if any(r.status == "error" for r in results):
        sys.exit(1)


if __name__ == "__main__":
    main()
