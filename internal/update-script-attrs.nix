# FLAKE_URI="$PWD" nix eval --raw --file ./internal/update-script-attrs.nix
let
  system = builtins.currentSystem;
  flake = builtins.getFlake (builtins.getEnv "FLAKE_URI");
  packages = flake.packages.${system};

  shouldUpdatePackage =
    name:
    (builtins.hasAttr "updateScript" packages.${name})
    && !(builtins.hasAttr "helmChart" packages.${name})
    && !(builtins.hasAttr "ociImage" packages.${name});

  attrs = builtins.filter shouldUpdatePackage (builtins.attrNames packages);
in
"attrs=${builtins.toJSON attrs}"
