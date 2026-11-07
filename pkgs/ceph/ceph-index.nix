{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "quay.io/ceph/ceph";
  lock = ./ceph-index.json;

  meta = {
    description = "Ceph container image mirror";
    homepage = "https://ceph.io";
    license = lib.licenses.lgpl21;
  };
}
