{ stdenv }:
let
  nixidy = builtins.getFlake (
    builtins.flakeRefToString (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixidy.locked
  );
in
nixidy.packages.${stdenv.hostPlatform.system}.generators.fromChartCRD
