{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "ceph-19-index";
  imageName = "quay.io/ceph/ceph";
  lock = ./ceph-19-index.json;
  # Ceph 19 (Squid) only: each supported major has its own index.
  tagPattern = "v19\\.[0-9]+\\.[0-9]+";

  meta = {
    description = "Ceph 19 container image mirror";
    homepage = "https://ceph.io";
    license = lib.licenses.lgpl21;
  };
}
