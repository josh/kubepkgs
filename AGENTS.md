# Agents Guide

## Setup

If `nix` is not installed, use the Determinate Systems installer:

```sh
$ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
$ . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Ensure flake inputs are downloaded before running in an offline sandbox:

```sh
$ nix flake archive
$ nix flake archive ./internal/
```

## Testing

```sh
$ nix flake check --show-trace --print-build-logs --keep-going
```

These flags will give you the most verbose output for debugging. When running in an offline sandox, you should append `--offline`.

## Formatting

`nix flake check` will also check if source files are formatted correctly. If there is a formatting issue, run `nix fmt` to fix it.

## Ordering

`nixfmt` does not reorder anything, so these are maintained by hand. They follow the de-facto convention in `NixOS/nixpkgs`, which is role-based rather than alphabetical.

### Package arguments

Order the `callPackage` argument set by role, and alphabetize only within the dependency group:

1. `lib`
2. Builder — `stdenvNoCC`, `buildGo127Module`
3. Source — `fetchFromGitHub`, and `kubepkgs` (it supplies a chart as `src`, plus `fetchhelm`, `renderHelmTemplate`, and `checkKubeImages`)
4. Dependencies, alphabetized — `jq`, `yq`. Packages a test consumes belong here, not in the group below
5. Passthru machinery — `nix-update-script`, `runCommand`

```nix
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  jq,
  nix-update-script,
  runCommand,
}:
```

Every argument list here is flat — no package reaches eight arguments. If one ever does, separate the groups with blank lines. Add `#` comments only when the groups are not self-evident.

### Derivation attributes

Order attributes by the build lifecycle:

`pname` → `version` → format flags (`__structuredAttrs`, `outputs`) → `src` → `vendorHash` → `nativeBuildInputs` → phases in lifecycle order (`buildCommand`, or `buildPhase` then `installPhase`) → `passthru` → `meta`

`pname` is always first and `meta` is always last, with `passthru` immediately before it.

### Wrapper call sites

Most packages wrap an `internal/` builder and pass an attribute set instead of building a derivation themselves. Only the handful that fetch upstream YAML directly, or copy files out of a chart, call `mkDerivation` and follow the attribute order above.

A `*-chart.nix` wrapping `kubepkgs.fetchhelm`: `pname` (only when it differs from the default `<chart>-chart`) → `url` → `chart` → `version` → `hash` → `ignoredVersions` → `crds` → `helmTestValues`/`helmTestArgs` → `meta`.

`crds` opts the chart into a committed CRD module: `file` is the generated module under the top-level `crds/`, and `values` is whatever its render needs. Generated modules never live under `pkgs/`, because every `pkgs/*/*.nix` is `callPackage`d and a module is not a derivation. `crds/` is excluded from `treefmt` because the generator emits parens `statix` would strip.

Modules are always rendered against `kubernetes.version` from this repo's own nixpkgs, so the Kubernetes version is owned here rather than inherited from whichever nixpkgs the generator happens to pin. It moves only when nixpkgs does, and the drift check shows what changed.

Setting `crds` adds a `tests.crds` drift check, so `nix flake check` fails when the committed module no longer matches the chart. `nix run .#update-crd-modules -- --write` regenerates it, and `update-helm-charts` does the same in the same commit as a version bump.

`ignoredVersions` holds exact upstream versions that `update-helm-charts` must never select, for releases that are published but broken. Always comment why, and delete the entry once upstream is fixed — it is a pin against a known-bad release, not a permanent ceiling.

A `*-manifests.nix` wrapping `kubepkgs.renderHelmTemplate`: `pname` → `src` (the chart) → `chartName` → `helmArgs`/`helmValues` when the render needs them → `meta`. The helper supplies `version` from `src`, a `parse` test, and `meta.platforms`, so none of those are repeated at the call site.

### JSON snapshots

A `pkgs/*/*.nix` paired with a same-named `.json` vendors a JSON payload fetched from an upstream HTTP endpoint. The `.json` is that payload re-serialized as 2-space JSON rather than the bytes off the wire, which keeps it prettier-clean and stable — endpoints serve minified or pretty bytes unpredictably, so the wire bytes churn even when nothing changed. The derivation's single output is that file, so `nix build` then `cat result` reproduces the payload.

`passthru.data` is the same payload parsed with `builtins.fromJSON`, so consumers read it at evaluation time instead of importing from derivation. `passthru.jsonSnapshot` is the refresh marker — `url`, plus the `file` and `snapshot` paths — and must stay small, because `update-json-snapshots` reads it with `nix eval --json`. Keep the payload out of it.

`nix run .#update-json-snapshots -- --dry-run` previews a refresh and `--write` applies one without committing. These packages carry no `passthru.updateScript`: the `json-snapshots` workflow job refreshes them, not the `update-script` sweep. A `tests.data` check asserts `passthru.data` still equals the built file, so the evaluation and build paths cannot drift.

### Exceptions

`internal/*.nix` mix nixpkgs dependencies with caller-supplied derivation parameters (`src`, `pname`, `chartName`, `helmValues`). Keep nixpkgs dependencies first, then the parameters, then the `?`-defaulted ones; do not interleave them.
