{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://charts.rook.io/release/";
  chart = "rook-ceph";
  version = "1.20.8";
  hash = "sha256-FjYMB9/J7F9/z9+qIrPo709ED49J/PyDWIkEO1pBh+M=";

  crds.file = ../../crds/rook-ceph.nix;

  meta = {
    description = "Helm chart for the Rook operator, orchestrating Ceph storage on Kubernetes";
    homepage = "https://github.com/rook/rook";
    license = lib.licenses.asl20;
  };
}
