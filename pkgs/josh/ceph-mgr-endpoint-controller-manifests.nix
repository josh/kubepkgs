{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "ceph-mgr-endpoint-controller-manifests";
  src = kubepkgs.ceph-mgr-endpoint-controller-chart;
  chartName = "ceph-mgr-endpoint-controller";

  meta = {
    description = "Kubernetes manifests for the Ceph manager endpoint controller";
    homepage = "https://github.com/josh/ceph-mgr-endpoint-controller/tree/main/charts/ceph-mgr-endpoint-controller";
    license = lib.licenses.mit;
  };
}
