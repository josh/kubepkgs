{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/home-operations/charts/tuppr";
  chart = "tuppr";
  version = "0.5.12";
  hash = "sha256-OpfRcpXaGoO9tU1CyUn30TigCxSmda6uJrRmghMMD1U=";

  crds.file = ../../crds/tuppr.nix;

  meta = {
    description = "Helm chart for the Talos Linux upgrade controller";
    homepage = "https://github.com/home-operations/tuppr";
    license = lib.licenses.agpl3Only;
  };
}
