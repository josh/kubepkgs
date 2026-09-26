import dataclasses
import datetime
import difflib
import json
import os
import re
import subprocess
import sys
import urllib.request

import click

CACERT_PATH = "@cacert@"
GH_PATH = "@gh@"
GIT_PATH = "@git@"
JQ_PATH = "@jq@"
NIX_PATH = "@nix@"

STORE_PREFIX = re.compile(r"^/nix/store/[^/]+/")

VERSION_LINE = re.compile(r'^(\s*version = ")([^"]+)(";)$', re.MULTILINE)

DISCOVER_EXPR = """
let
  ps = (builtins.getFlake "@root@").packages.${builtins.currentSystem};
in
builtins.listToAttrs (
  map (n: {
    name = n;
    value = ps.${n}.jsonSnapshot;
  }) (builtins.filter (n: ps.${n} ? jsonSnapshot) (builtins.attrNames ps))
)
"""


@dataclasses.dataclass
class JsonSnapshot:
    attr: str
    pname: str
    version: str
    url: str
    filter: str | None
    file: str
    snapshot: str


@dataclasses.dataclass
class Result:
    entry: JsonSnapshot
    status: str
    latest: str | None = None
    message: str = ""
    snapshot: str | None = None


def log(message: str) -> None:
    print(message, file=sys.stderr)


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    log(f"+ {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True, check=False, **kwargs)
    if result.returncode != 0 and result.stderr:
        log(result.stderr.rstrip())
    result.check_returncode()
    return result


def discover(repo_root: str) -> list[JsonSnapshot]:
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
        JsonSnapshot(
            attr=attr,
            pname=info["pname"],
            version=info["version"],
            url=info["url"],
            filter=info.get("filter"),
            file=STORE_PREFIX.sub("", info["file"]),
            snapshot=STORE_PREFIX.sub("", info["snapshot"]),
        )
        for attr, info in sorted(data.items())
    ]


def fetch(url: str, jq_filter: str | None) -> str:
    """Re-serialize instead of storing the response bytes.

    api.github.com/meta serves the same payload minified or pretty-printed depending on the
    day, so the wire bytes churn when nothing changed, and a minified body would fail
    treefmt's prettier check. Re-serializing a filtered payload through the same path keeps
    both forms canonical.
    """
    headers = {
        "User-Agent": "update-json-snapshots",
        "Accept": "application/vnd.github+json",
    }
    log(f"+ fetch {url}")
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=60) as response:
        raw = response.read()
    if jq_filter:
        raw = run([JQ_PATH, jq_filter], input=raw.decode()).stdout
    return json.dumps(json.loads(raw), indent=2) + "\n"


def rewrite_version(content: str, old: str, new: str) -> str:
    match = VERSION_LINE.search(content)
    if match is None:
        raise ValueError("no version line found")
    if match.group(2) != old:
        raise ValueError(f'version line is "{match.group(2)}", expected "{old}"')
    return VERSION_LINE.sub(rf"\g<1>{new}\g<3>", content, count=1)


def git(*args: str) -> str:
    return run([GIT_PATH, *args]).stdout.strip()


def gh(*args: str) -> str:
    return run([GH_PATH, *args]).stdout.strip()


def resolve(entries: list[JsonSnapshot]) -> list[Result]:
    results = []
    for entry in entries:
        try:
            snapshot = fetch(entry.url, entry.filter)
            with open(entry.snapshot, "r") as f:
                current = f.read()
        except (OSError, ValueError, subprocess.CalledProcessError) as err:
            results.append(Result(entry, "error", None, str(err)))
            continue
        if current == snapshot:
            results.append(Result(entry, "up-to-date", entry.version))
            continue
        version = f"0-unstable-{datetime.datetime.now(datetime.UTC):%Y-%m-%d}"
        results.append(Result(entry, "update", version, snapshot=snapshot))
    return results


def apply_snapshot(result: Result, dry_run: bool, push: bool) -> Result:
    entry = result.entry
    version = result.latest
    snapshot = result.snapshot

    with open(entry.file, "r") as f:
        nix = f.read()
    updated = rewrite_version(nix, entry.version, version)

    message = f"{entry.pname}: {entry.version} -> {version}"

    if dry_run:
        with open(entry.snapshot, "r") as f:
            original = f.read()
        sys.stdout.writelines(
            difflib.unified_diff(
                original.splitlines(keepends=True),
                snapshot.splitlines(keepends=True),
                fromfile=entry.snapshot,
                tofile=entry.snapshot,
            )
        )
        sys.stdout.writelines(
            difflib.unified_diff(
                nix.splitlines(keepends=True),
                updated.splitlines(keepends=True),
                fromfile=entry.file,
                tofile=entry.file,
            )
        )
        return Result(entry, "update", version, message)

    with open(entry.snapshot, "w") as f:
        f.write(snapshot)
    with open(entry.file, "w") as f:
        f.write(updated)

    if not push:
        return Result(entry, "updated", version, message)

    git("add", "--", entry.snapshot, entry.file)
    git("commit", "--message", message, "--", entry.snapshot, entry.file)

    branch = f"update-{entry.attr}"
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
            f"Update {entry.attr}",
            "--body",
            message,
        )
    gh("pr", "merge", "--merge", "--auto", branch)
    return Result(entry, "opened", version, message)


def report(results: list[Result]) -> None:
    width = max((len(r.entry.attr) for r in results), default=10)
    for r in sorted(results, key=lambda r: (r.status, r.entry.attr)):
        note = ""
        if r.message and r.status in ("error", "skipped"):
            note = f"  ({r.message.splitlines()[0]})"
        log(
            f"{r.entry.attr:<{width}}  {r.entry.version:>22} -> "
            f"{r.latest or '-':<22} {r.status}{note}"
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
    rows = ["| snapshot | current | latest | status |", "| --- | --- | --- | --- |"]
    for r in sorted(changed, key=lambda r: (r.status, r.entry.attr)):
        rows.append(
            f"| {r.entry.attr} | {r.entry.version} | {r.latest or '-'} | {r.status} |"
        )
    with open(path, "a") as f:
        f.write("\n".join(rows) + "\n")


@click.command()
@click.option("--only", multiple=True, help="Limit to these attributes.")
@click.option("--dry-run", is_flag=True, help="Print the diff instead of applying it.")
@click.option(
    "--push", is_flag=True, help="Commit, push, and open one PR per snapshot."
)
@click.option("--write", is_flag=True, help="Edit files without committing.")
def main(only, dry_run, push, write):
    os.environ.setdefault("SSL_CERT_FILE", CACERT_PATH)

    entries = discover(os.getcwd())
    if only:
        entries = [i for i in entries if i.attr in set(only)]
    log(f"discovered {len(entries)} json snapshots")

    results = resolve(entries)

    if dry_run or write or push:
        base = git("rev-parse", "HEAD") if push else None
        applied = []
        for result in results:
            if result.status != "update":
                applied.append(result)
                continue
            try:
                applied.append(apply_snapshot(result, dry_run, push))
            except (ValueError, subprocess.CalledProcessError, OSError) as err:
                applied.append(Result(result.entry, "error", result.latest, str(err)))
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
