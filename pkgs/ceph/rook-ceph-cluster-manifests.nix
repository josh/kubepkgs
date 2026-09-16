{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "rook-ceph-cluster-manifests";
  src = kubepkgs.rook-ceph-cluster-chart;
  chartName = "rook-ceph-cluster";

  meta = {
    description = "Kubernetes manifests creating Rook resources to configure a Ceph cluster";
    homepage = "https://github.com/rook/rook";
    license = lib.licenses.asl20;
  };
}
