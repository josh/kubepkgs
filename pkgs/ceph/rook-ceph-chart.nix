{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://charts.rook.io/release/";
  chart = "rook-ceph";
  version = "1.21.1";
  hash = "sha256-QehfCXPmYingrMbMHJenw1mw1/aPl3PxioKcm8fIecI=";

  crds.file = ../../crds/rook-ceph.nix;

  meta = {
    description = "Helm chart for the Rook operator, orchestrating Ceph storage on Kubernetes";
    homepage = "https://github.com/rook/rook";
    license = lib.licenses.asl20;
  };
}
