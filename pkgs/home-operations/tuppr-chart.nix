{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/home-operations/charts/tuppr";
  chart = "tuppr";
  version = "0.5.13";
  hash = "sha256-+esie/QPWf24lKd1uZ1m49HmCQ72ksHMoigIA28qJ/c=";

  crds.file = ../../crds/tuppr.nix;

  meta = {
    description = "Helm chart for the Talos Linux upgrade controller";
    homepage = "https://github.com/home-operations/tuppr";
    license = lib.licenses.agpl3Only;
  };
}
