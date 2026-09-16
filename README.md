# kubepkgs

My Kubernetes Nix Repository. Vendored upstream Helm charts (`*-chart`) and the manifests rendered from them (`*-manifests`), pinned and cached like any other Nix package.

## Outputs

`overlays.default`

```
$ nix repl .
> pkgs = import <nixpkgs> { overlays = [ overlays.default ]; }
> pkgs.kubepkgs
```

```nix
# NixOS or Home Manager module
{
  nixpkgs.overlays = [
    kubepkgs.overlays.default
  ];
}
```
