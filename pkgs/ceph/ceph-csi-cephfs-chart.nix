{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://ceph.github.io/csi-charts";
  chart = "ceph-csi-cephfs";
  version = "3.18.0";
  hash = "sha256-LaFo5j6Dk1oywjr/RJx9fdzVLnunDFjzgDu1SpsY7M4=";

  meta = {
    description = "Container Storage Interface (CSI) driver, provisioner, snapshotter, resizer and attacher for Ceph cephfs";
    homepage = "https://github.com/ceph/ceph-csi";
    license = lib.licenses.asl20;
  };
}
