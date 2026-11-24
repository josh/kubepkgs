{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://charts.rook.io/release/";
  chart = "rook-ceph-cluster";
  version = "1.21.3";
  hash = "sha256-Ksr0I5gWCxoSXbts/I8MwaPEfH9Ux6WDBAijUVi9e9o=";

  meta = {
    description = "Manages a single Ceph cluster namespace for Rook";
    homepage = "https://github.com/rook/rook";
    license = lib.licenses.asl20;
  };
}
