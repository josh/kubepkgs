{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "ceph-21-index";
  imageName = "quay.io/ceph/ceph";
  lock = ./ceph-21-index.json;
  # Ceph 21 (Umbrella) only: each supported major has its own index.
  tagPattern = "v21\\.[0-9]+\\.[0-9]+";

  meta = {
    description = "Ceph 21 container image mirror";
    homepage = "https://ceph.io";
    license = lib.licenses.lgpl21;
  };
}
