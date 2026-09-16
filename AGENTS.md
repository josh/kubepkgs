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
2. Builder — `stdenvNoCC`
3. Source — `fetchFromGitHub`, and `kubepkgs` (it supplies a chart as `src`, plus `fetchhelm`, `renderHelmTemplate`, and `checkKubeImages`)
4. Dependencies, alphabetized — `kubernetes-helm`, `yq`. Packages a test consumes belong here, not in the group below
5. Passthru machinery — `nix-update-script`, `runCommand`

```nix
{
  lib,
  stdenvNoCC,
  kubepkgs,
  kubernetes-helm,
  yq,
  runCommand,
}:
```

Every argument list here is flat — no package reaches eight arguments. If one ever does, separate the groups with blank lines. Add `#` comments only when the groups are not self-evident.

### Derivation attributes

Order attributes by the build lifecycle:

`pname` → `version` → `__structuredAttrs` → `src` → `nativeBuildInputs` → builder configuration (`helmChartName`, `helmArgs`, `helmValues`) → phases in lifecycle order (`buildCommand`, or `buildPhase` then `installPhase`) → `passthru` → `meta`

`pname` is always first and `meta` is always last, with `passthru` immediately before it.

### Vendored charts

A `*-chart.nix` that wraps `kubepkgs.fetchhelm` passes an attribute set instead of building a derivation itself. Order it `pname` (only when it differs from the default `<chart>-chart`) → `url` → `chart` → `version` → `hash` → `helmTestValues`/`helmTestArgs` → `meta`.

### Exceptions

`internal/*.nix` mix nixpkgs dependencies with caller-supplied derivation parameters (`src`, `pname`, `chartName`, `helmValues`). Keep nixpkgs dependencies first, then the parameters, then the `?`-defaulted ones; do not interleave them.
