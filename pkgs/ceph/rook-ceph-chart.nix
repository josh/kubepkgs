{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://charts.rook.io/release/";
  chart = "rook-ceph";
  version = "1.21.0";
  hash = "sha256-MrJabHk/3Cd9BERqwmy/ZljUqc9OPKp2cfvMA1XjQeU=";

  crds.file = ../../crds/rook-ceph.nix;

  meta = {
    description = "Helm chart for the Rook operator, orchestrating Ceph storage on Kubernetes";
    homepage = "https://github.com/rook/rook";
    license = lib.licenses.asl20;
  };
}
