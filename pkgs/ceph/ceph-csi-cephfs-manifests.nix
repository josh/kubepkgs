{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "ceph-csi-cephfs-manifests";
  src = kubepkgs.ceph-csi-cephfs-chart;
  chartName = "ceph-csi-cephfs";

  meta = {
    description = "Container Storage Interface (CSI) driver, provisioner, snapshotter, resizer and attacher for Ceph cephfs";
    homepage = "https://github.com/ceph/ceph-csi/tree/devel/charts/ceph-csi-cephfs";
    license = lib.licenses.asl20;
  };
}
