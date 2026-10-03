import dataclasses
import difflib
import json
import os
import re
import subprocess
import sys

import click

CACERT_PATH = "@cacert@"
CRANE_PATH = "@crane@"
GH_PATH = "@gh@"
GIT_PATH = "@git@"
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
    value = ps.${n}.ociImage;
  }) (builtins.filter (n: ps.${n} ? ociImage) (builtins.attrNames ps))
)
"""


@dataclasses.dataclass
class Image:
    attr: str
    pname: str
    image_name: str
    tag: str
    digest: str
    lock: str


@dataclasses.dataclass
class Result:
    image: Image
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
    major, minor, patch, suffix = m.groups()
    return (int(major), int(minor or 0), int(patch or 0)), suffix


def select_version(candidates: list[str], current: str) -> str | None:
    """Follow the numbers, never the suffix.

    A tag's suffix identifies the image variant -- redis "8.10.1-alpine" and docker
    "29.8.1-dind" are different images from "8.10.1" and "29.8.1", not newer ones. So a
    candidate only qualifies when its suffix matches the pinned tag exactly. A pin on a
    numbered prerelease such as "-beta1" therefore never advances to "-beta2"; failing to
    update beats switching channels.
    """
    parsed_current = parse_version(current)
    if parsed_current is None:
        return None
    _, suffix = parsed_current

    valid = [
        (raw, parsed)
        for raw, parsed in ((raw, parse_version(raw)) for raw in candidates)
        if parsed is not None and parsed[1] == suffix
    ]
    if not valid:
        return None
    # "1.38" and "1.38.0" parse equal; prefer the more specific tag.
    return max(valid, key=lambda item: (item[1][0], item[0].count(".")))[0]


def discover(repo_root: str) -> list[Image]:
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
        Image(
            attr=attr,
            pname=info["pname"],
            image_name=info["imageName"],
            tag=info["tag"],
            digest=info["digest"],
            lock=STORE_PREFIX.sub("", info["lock"]),
        )
        for attr, info in sorted(data.items())
    ]


def crane_tags(image_name: str) -> list[str]:
    result = run([CRANE_PATH, "ls", image_name])
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def crane_digest(image_name: str, tag: str) -> str:
    return run([CRANE_PATH, "digest", f"{image_name}:{tag}"]).stdout.strip()


def crane_manifest(image_name: str, digest: str) -> dict:
    return json.loads(run([CRANE_PATH, "manifest", f"{image_name}@{digest}"]).stdout)


def resolve_latest(images: list[Image]) -> list[Result]:
    results = []
    for image in images:
        try:
            candidates = crane_tags(image.image_name)
        except (OSError, subprocess.CalledProcessError) as err:
            results.append(Result(image, "error", None, str(err)))
            continue
        latest = select_version(candidates, image.tag)
        if latest is None:
            results.append(Result(image, "error", None, "no usable tag published"))
            continue
        results.append(classify(image, latest))
    return results


def classify(image: Image, latest: str) -> Result:
    old_parsed = parse_version(image.tag)
    latest_parsed = parse_version(latest)
    if old_parsed is None:
        return Result(image, "skipped", latest, "unparseable pinned tag")
    if latest_parsed is None:
        return Result(image, "skipped", latest, "unparseable published tag")
    if latest_parsed[0] < old_parsed[0]:
        return Result(image, "skipped", latest, "refusing downgrade")
    if latest == image.tag:
        return Result(image, "up-to-date", latest)
    return Result(image, "update", latest)


def build_lock(image_name: str, tag: str, digest: str) -> dict:
    root = crane_manifest(image_name, digest)
    manifests = [m["digest"] for m in root.get("manifests", [])]

    blobs: list[str] = []
    seen: set[str] = set()

    def add(child: dict) -> None:
        candidates = [child["config"]["digest"]]
        candidates += [layer["digest"] for layer in child.get("layers", [])]
        for candidate in candidates:
            if candidate not in seen:
                seen.add(candidate)
                blobs.append(candidate)

    if manifests:
        for child_digest in manifests:
            add(crane_manifest(image_name, child_digest))
    else:
        add(root)

    return {"tag": tag, "digest": digest, "manifests": manifests, "blobs": blobs}


def git(*args: str) -> str:
    return run([GIT_PATH, *args]).stdout.strip()


def gh(*args: str) -> str:
    return run([GH_PATH, *args]).stdout.strip()


def apply_image(image: Image, new_tag: str, dry_run: bool, push: bool) -> Result:
    new_digest = crane_digest(image.image_name, new_tag)
    lock = (
        json.dumps(build_lock(image.image_name, new_tag, new_digest), indent=2) + "\n"
    )

    with open(image.lock, "r") as f:
        original = f.read()

    message = f"{image.pname}: {image.tag} -> {new_tag}"

    if dry_run:
        sys.stdout.writelines(
            difflib.unified_diff(
                original.splitlines(keepends=True),
                lock.splitlines(keepends=True),
                fromfile=image.lock,
                tofile=image.lock,
            )
        )
        return Result(image, "update", new_tag, message)

    with open(image.lock, "w") as f:
        f.write(lock)

    if not push:
        return Result(image, "updated", new_tag, message)

    git("add", "--", image.lock)
    git("commit", "--message", message, "--", image.lock)

    branch = f"update-{image.attr}"
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
            f"Update {image.attr}",
            "--body",
            message,
        )
    gh("pr", "merge", "--merge", "--auto", branch)
    return Result(image, "opened", new_tag, message)


def report(results: list[Result]) -> None:
    width = max((len(r.image.attr) for r in results), default=10)
    for r in sorted(results, key=lambda r: (r.status, r.image.attr)):
        note = ""
        if r.message and r.status in ("error", "skipped"):
            note = f"  ({r.message.splitlines()[0]})"
        log(
            f"{r.image.attr:<{width}}  {r.image.tag:>12} -> "
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
    rows = ["| image | current | latest | status |", "| --- | --- | --- | --- |"]
    for r in sorted(changed, key=lambda r: (r.status, r.image.attr)):
        rows.append(
            f"| {r.image.attr} | {r.image.tag} | {r.latest or '-'} | {r.status} |"
        )
    with open(path, "a") as f:
        f.write("\n".join(rows) + "\n")


def init_lock(image_ref: str, lock_path: str) -> None:
    """Accepts <imageName>:<tag> or <imageName>:<tag>@<digest>.

    Pass the digest to pin exactly what is deployed; tags move, so resolving one here can
    pick up content the cluster has never run.
    """
    ref, _, digest = image_ref.partition("@")
    image_name, _, tag = ref.rpartition(":")
    if not image_name or not tag:
        raise ValueError(f"expected <imageName>:<tag>[@<digest>], got {image_ref}")
    if not digest:
        digest = crane_digest(image_name, tag)
    lock = json.dumps(build_lock(image_name, tag, digest), indent=2) + "\n"
    with open(lock_path, "w") as f:
        f.write(lock)
    log(f"wrote {lock_path} for {image_name}:{tag} at {digest}")


@click.command()
@click.option(
    "--init",
    "init_ref",
    metavar="IMAGE:TAG",
    help="Generate a lockfile for an image not yet packaged.",
)
@click.option(
    "--lock",
    "lock_path",
    metavar="PATH",
    help="Lockfile to write with --init.",
)
@click.option("--only", multiple=True, help="Limit to these attributes.")
@click.option("--dry-run", is_flag=True, help="Print the diff instead of applying it.")
@click.option("--push", is_flag=True, help="Commit, push, and open one PR per image.")
@click.option("--write", is_flag=True, help="Edit files without committing.")
def main(init_ref, lock_path, only, dry_run, push, write):
    os.environ.setdefault("SSL_CERT_FILE", CACERT_PATH)

    if init_ref:
        if not lock_path:
            raise click.UsageError("--init requires --lock")
        init_lock(init_ref, lock_path)
        return

    images = discover(os.getcwd())
    if only:
        images = [i for i in images if i.attr in set(only)]
    log(f"discovered {len(images)} images")

    results = resolve_latest(images)

    if dry_run or write or push:
        base = git("rev-parse", "HEAD") if push else None
        applied = []
        for result in results:
            if result.status != "update":
                applied.append(result)
                continue
            try:
                applied.append(apply_image(result.image, result.latest, dry_run, push))
            except (ValueError, subprocess.CalledProcessError, OSError) as err:
                applied.append(Result(result.image, "error", result.latest, str(err)))
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
