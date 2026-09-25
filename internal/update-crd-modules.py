import dataclasses
import difflib
import json
import os
import re
import subprocess
import sys

import click

GH_PATH = "@gh@"
GIT_PATH = "@git@"
NIX_PATH = "@nix@"

STORE_PREFIX = re.compile(r"^/nix/store/[^/]+/")

DISCOVER_EXPR = """
let
  ps = (builtins.getFlake "@root@").packages.${builtins.currentSystem};
in
builtins.listToAttrs (
  map (n: {
    name = n;
    value = ps.${n}.crdModule;
  }) (builtins.filter (n: (ps.${n}.crdModule or null) != null) (builtins.attrNames ps))
)
"""


@dataclasses.dataclass
class Module:
    attr: str
    pname: str
    name: str
    version: str
    file: str


@dataclasses.dataclass
class Result:
    module: Module
    status: str
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


def discover(repo_root: str) -> list[Module]:
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
        Module(
            attr=attr,
            pname=info["pname"],
            name=info["name"],
            version=info["version"],
            file=STORE_PREFIX.sub("", info["file"]),
        )
        for attr, info in sorted(data.items())
    ]


def generate(repo_root: str, module: Module) -> str:
    cmd = [
        NIX_PATH,
        "build",
        "--no-link",
        "--print-out-paths",
        f"{repo_root}#{module.attr}.crdModuleGenerated",
    ]
    return run(cmd).stdout.strip()


def git(*args: str) -> str:
    return run([GIT_PATH, *args]).stdout.strip()


def gh(*args: str) -> str:
    return run([GH_PATH, *args]).stdout.strip()


def apply_module(
    repo_root: str, module: Module, dry_run: bool, write: bool, push: bool
) -> Result:
    with open(generate(repo_root, module), "r") as f:
        content = f.read()

    try:
        with open(module.file, "r") as f:
            original = f.read()
    except FileNotFoundError:
        original = ""

    if original == content:
        return Result(module, "up-to-date")

    message = f"{module.pname}: regenerate CRD module for {module.version}"

    if dry_run:
        sys.stdout.writelines(
            difflib.unified_diff(
                original.splitlines(keepends=True),
                content.splitlines(keepends=True),
                fromfile=module.file,
                tofile=module.file,
            )
        )
        return Result(module, "update", message)

    if not (write or push):
        return Result(module, "update", message)

    os.makedirs(os.path.dirname(module.file) or ".", exist_ok=True)
    with open(module.file, "w") as f:
        f.write(content)

    if not push:
        return Result(module, "updated", message)

    git("add", "--", module.file)
    git("commit", "--message", message, "--", module.file)

    branch = f"update-{module.attr}-crds"
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
            f"Update {module.attr} CRD module",
            "--body",
            message,
        )
    gh("pr", "merge", "--merge", "--auto", branch)
    return Result(module, "opened", message)


def report(results: list[Result]) -> None:
    width = max((len(r.module.attr) for r in results), default=10)
    for r in sorted(results, key=lambda r: (r.status, r.module.attr)):
        note = ""
        if r.message and r.status in ("error", "skipped"):
            note = f"  ({r.message.splitlines()[0]})"
        log(f"{r.module.attr:<{width}}  {r.module.version:>12}  {r.status}{note}")
    counts: dict[str, int] = {}
    for r in results:
        counts[r.status] = counts.get(r.status, 0) + 1
    log(", ".join(f"{n} {status}" for status, n in sorted(counts.items())))


def write_github_summary(results: list[Result]) -> None:
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    changed = [r for r in results if r.status != "up-to-date"]
    if not path or not changed:
        return
    rows = ["| module | version | status |", "| --- | --- | --- |"]
    for r in sorted(changed, key=lambda r: (r.status, r.module.attr)):
        rows.append(f"| {r.module.attr} | {r.module.version} | {r.status} |")
    with open(path, "a") as f:
        f.write("\n".join(rows) + "\n")


@click.command()
@click.option("--only", multiple=True, help="Limit to these attributes.")
@click.option("--dry-run", is_flag=True, help="Print the diff instead of applying it.")
@click.option("--push", is_flag=True, help="Commit, push, and open one PR per module.")
@click.option("--write", is_flag=True, help="Edit files without committing.")
def main(only, dry_run, push, write):
    repo_root = os.getcwd()

    modules = discover(repo_root)
    if only:
        modules = [m for m in modules if m.attr in set(only)]
    log(f"discovered {len(modules)} CRD modules")

    base = git("rev-parse", "HEAD") if push else None
    results = []
    for module in modules:
        try:
            results.append(apply_module(repo_root, module, dry_run, write, push))
        except (ValueError, subprocess.CalledProcessError, OSError) as err:
            results.append(Result(module, "error", str(err)))
        finally:
            if push and base:
                git("reset", "--hard", base)

    report(results)
    write_github_summary(results)

    if any(r.status == "error" for r in results):
        sys.exit(1)


if __name__ == "__main__":
    main()
