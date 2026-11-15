import base64
import gzip
import json
import os
import pathlib
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET

import click

CACERT_PATH = "@cacert@"
GIT_PATH = "@git@"

PACKAGES = ("librados-devel", "libradosstriper-devel")
ARCHES = ("aarch64", "x86_64")

REPO_NS = "{http://linux.duke.edu/metadata/repo}"
COMMON_NS = "{http://linux.duke.edu/metadata/common}"


def log(message: str) -> None:
    print(message, file=sys.stderr)


def fetch(url: str) -> bytes:
    log(f"+ fetch {url}")
    request = urllib.request.Request(url, headers={"User-Agent": "update-ceph-devel"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def head(url: str) -> None:
    log(f"+ head {url}")
    request = urllib.request.Request(
        url, method="HEAD", headers={"User-Agent": "update-ceph-devel"}
    )
    with urllib.request.urlopen(request, timeout=60):
        pass


def primary_url(series: str, arch: str) -> str:
    repomd = ET.fromstring(fetch(f"{series}/{arch}/repodata/repomd.xml"))
    for data in repomd.iter(f"{REPO_NS}data"):
        if data.get("type") == "primary":
            location = data.find(f"{REPO_NS}location")
            if location is not None:
                return f"{series}/{arch}/{location.get('href')}"
    raise click.ClickException(f"{series}/{arch}: repomd.xml lists no primary metadata")


def sri(hex_digest: str) -> str:
    return "sha256-" + base64.b64encode(bytes.fromhex(hex_digest)).decode()


def version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def scan(series: str, arch: str, release: str) -> dict[str, dict[str, str]]:
    """Map version -> package name -> SRI hash for one architecture."""
    found: dict[str, dict[str, str]] = {}
    root = ET.fromstring(gzip.decompress(fetch(primary_url(series, arch))))
    for package in root.iter(f"{COMMON_NS}package"):
        name = package.findtext(f"{COMMON_NS}name")
        if name not in PACKAGES or package.findtext(f"{COMMON_NS}arch") != arch:
            continue
        version = package.find(f"{COMMON_NS}version")
        checksum = package.find(f"{COMMON_NS}checksum")
        location = package.find(f"{COMMON_NS}location")
        if version is None or checksum is None or location is None:
            continue
        ver, rel = version.get("ver"), version.get("rel")
        if rel != release or checksum.get("type") != "sha256":
            continue
        if location.get("href") != f"{name}-{ver}-{rel}.{arch}.rpm":
            continue
        found.setdefault(ver, {})[name] = sri(checksum.text or "")
    return {
        ver: hashes for ver, hashes in found.items() if set(hashes) == set(PACKAGES)
    }


def resolve(series: str) -> dict:
    el = series.rstrip("/").rsplit("/", 1)[-1]
    if not el.startswith("el"):
        raise click.ClickException(f"{series}: expected a URL ending in el<N>")
    release = f"0.{el}"
    per_arch = {arch: scan(series, arch, release) for arch in ARCHES}
    common = set.intersection(*(set(versions) for versions in per_arch.values()))
    if not common:
        raise click.ClickException(
            f"{series}: no version carries {', '.join(PACKAGES)} for every arch"
        )
    version = max(common, key=version_key)
    base = series.rstrip("/").rsplit("/", 2)[0]
    for arch in ARCHES:
        for name in PACKAGES:
            head(
                f"{base}/rpm-{version}/{el}/{arch}/{name}-{version}-{release}.{arch}.rpm"
            )
    return {
        "version": version,
        "hashes": {arch: per_arch[arch][version] for arch in ARCHES},
    }


def serialize(lock: dict) -> str:
    return json.dumps(lock, indent=2, sort_keys=True) + "\n"


@click.command()
@click.option(
    "--lock",
    "lock_path",
    required=True,
    type=click.Path(dir_okay=False, path_type=pathlib.Path),
    help="Lock file to refresh, relative to the repo root; created when missing.",
)
@click.option(
    "--series",
    required=True,
    help="Release series repository, such as https://download.ceph.com/rpm-tentacle/el9.",
)
@click.option("--commit", is_flag=True, help="Commit the refreshed lock.")
def main(lock_path: pathlib.Path, series: str, commit: bool) -> None:
    os.environ.setdefault("SSL_CERT_FILE", CACERT_PATH)
    current = lock_path.read_text() if lock_path.exists() else None
    lock = resolve(series)
    updated = serialize(lock)
    if updated == current:
        log(f"{lock_path}: {lock['version']} is current")
        return
    lock_path.write_text(updated)
    log(f"wrote {lock_path} for {lock['version']}")
    if commit:
        message = f"Update {lock_path.stem} to {lock['version']}"
        subprocess.run(
            [GIT_PATH, "commit", "--message", message, "--", str(lock_path)], check=True
        )


if __name__ == "__main__":
    main()
