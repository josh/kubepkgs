{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "quay.io/cephcsi/cephcsi";
  lock = ./cephcsi-index.json;

  meta = {
    description = "Ceph CSI driver container image mirror";
    homepage = "https://github.com/ceph/ceph-csi";
    license = lib.licenses.asl20;
  };
}
