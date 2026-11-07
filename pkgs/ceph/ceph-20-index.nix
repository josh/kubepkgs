{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "ceph-20-index";
  imageName = "quay.io/ceph/ceph";
  lock = ./ceph-20-index.json;
  # Stay on Ceph 20 (Tentacle): a new major is a cluster upgrade, not an image bump.
  tagPattern = "v20\\.[0-9]+\\.[0-9]+";

  meta = {
    description = "Ceph 20 container image mirror";
    homepage = "https://ceph.io";
    license = lib.licenses.lgpl21;
  };
}
