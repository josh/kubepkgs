{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://ceph.github.io/csi-charts";
  chart = "ceph-csi-cephfs";
  version = "3.17.1";
  hash = "sha256-iCSXKGBN9bXkm/EfA1CChd/eYjgtYH+yIB1xCjnZHus=";

  # 3.18.0 ships quay.io/cephcsi/cephcsi:v3.18.0, whose manifest index labels both
  # children linux/amd64 -- the arm64 build carries amd64 metadata -- so the image
  # cannot be pulled on arm64. Drop this once upstream republishes a correct index.
  ignoredVersions = [ "3.18.0" ];

  meta = {
    description = "Container Storage Interface (CSI) driver, provisioner, snapshotter, resizer and attacher for Ceph cephfs";
    homepage = "https://github.com/ceph/ceph-csi";
    license = lib.licenses.asl20;
  };
}
