{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://charts.rook.io/release/";
  chart = "rook-ceph-cluster";
  version = "1.21.2";
  hash = "sha256-8QDPjVtGrjtsUdWd1g/rPdiLpl4YGxUSIhVZVtaJcNI=";

  meta = {
    description = "Manages a single Ceph cluster namespace for Rook";
    homepage = "https://github.com/rook/rook";
    license = lib.licenses.asl20;
  };
}
