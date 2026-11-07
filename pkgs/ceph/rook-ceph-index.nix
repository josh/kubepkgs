{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "rook-ceph-index";
  imageName = "docker.io/rook/ceph";
  lock = ./rook-ceph-index.json;

  meta = {
    description = "Rook Ceph operator container image mirror";
    homepage = "https://rook.io";
    license = lib.licenses.asl20;
  };
}
