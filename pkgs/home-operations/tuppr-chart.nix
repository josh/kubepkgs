{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/home-operations/charts/tuppr";
  chart = "tuppr";
  version = "0.5.14";
  hash = "sha256-PnNp/kK44daXU14dog1BB2ujt+axj6HEoBnkE/Mk8nE=";

  crds.file = ../../crds/tuppr.nix;

  meta = {
    description = "Helm chart for the Talos Linux upgrade controller";
    homepage = "https://github.com/home-operations/tuppr";
    license = lib.licenses.agpl3Only;
  };
}
