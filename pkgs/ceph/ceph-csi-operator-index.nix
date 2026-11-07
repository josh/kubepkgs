{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "quay.io/cephcsi/ceph-csi-operator";
  lock = ./ceph-csi-operator-index.json;

  meta = {
    description = "Ceph CSI operator container image mirror";
    homepage = "https://github.com/ceph/ceph-csi-operator";
    license = lib.licenses.asl20;
  };
}
