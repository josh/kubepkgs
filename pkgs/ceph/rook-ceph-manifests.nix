{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "rook-ceph-manifests";
  src = kubepkgs.rook-ceph-chart;
  chartName = "rook-ceph";

  meta = {
    description = "Kubernetes manifests for the Rook operator, orchestrating Ceph storage on Kubernetes";
    homepage = "https://github.com/rook/rook";
    license = lib.licenses.asl20;
  };
}
