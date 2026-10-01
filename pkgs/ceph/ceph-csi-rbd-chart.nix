{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://ceph.github.io/csi-charts";
  chart = "ceph-csi-rbd";
  version = "3.18.1";
  hash = "sha256-YEsh2lYNqMgZSD8lDDAcN5sALoqLch+EkPXto3eK3l0=";

  # 3.18.0 ships quay.io/cephcsi/cephcsi:v3.18.0, whose manifest index labels both
  # children linux/amd64 -- the arm64 build carries amd64 metadata -- so the image
  # cannot be pulled on arm64. Drop this once upstream republishes a correct index.
  ignoredVersions = [ "3.18.0" ];

  meta = {
    description = "Container Storage Interface (CSI) driver, provisioner, snapshotter, resizer and attacher for Ceph RBD";
    homepage = "https://github.com/ceph/ceph-csi";
    license = lib.licenses.asl20;
  };
}
