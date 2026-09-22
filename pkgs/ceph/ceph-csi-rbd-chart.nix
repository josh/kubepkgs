{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://ceph.github.io/csi-charts";
  chart = "ceph-csi-rbd";
  version = "3.18.0";
  hash = "sha256-VMhj7OwmgsNvfE0zWOwV7J4M1Me0ADfZH4vw3o2xAks=";

  meta = {
    description = "Container Storage Interface (CSI) driver, provisioner, snapshotter, resizer and attacher for Ceph RBD";
    homepage = "https://github.com/ceph/ceph-csi";
    license = lib.licenses.asl20;
  };
}
