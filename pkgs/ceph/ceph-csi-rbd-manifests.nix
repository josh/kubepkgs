{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "ceph-csi-rbd-manifests";
  src = kubepkgs.ceph-csi-rbd-chart;
  chartName = "ceph-csi-rbd";

  meta = {
    description = "Container Storage Interface (CSI) driver, provisioner, snapshotter, resizer and attacher for Ceph RBD";
    homepage = "https://github.com/ceph/ceph-csi/tree/devel/charts/ceph-csi-rbd";
    license = lib.licenses.asl20;
  };
}
