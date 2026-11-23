# FLAKE_URI="$PWD" [UPDATE_NIX_ATTR_PATH=foo] nix eval --raw --impure --file ./internal/update-script-matrix.nix
let
  system = builtins.currentSystem;
  flake = builtins.getFlake (builtins.getEnv "FLAKE_URI");
  only = builtins.getEnv "UPDATE_NIX_ATTR_PATH";
  packages = flake.packages.${system};

  shouldUpdatePackage =
    name:
    (builtins.hasAttr name packages)
    && (builtins.hasAttr "updateScript" packages.${name})
    && !(builtins.hasAttr "helmChart" packages.${name})
    && !(builtins.hasAttr "ociImage" packages.${name});

  attrs = builtins.filter shouldUpdatePackage (
    if only == "" then builtins.attrNames packages else [ only ]
  );
in
''
  matrix=${builtins.toJSON { include = builtins.map (attr: { inherit attr; }) attrs; }}
  has-packages=${if attrs == [ ] then "false" else "true"}
''
