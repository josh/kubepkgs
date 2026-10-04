{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "kube-ups-taint-manifests";
  src = kubepkgs.kube-ups-taint-chart;
  chartName = "kube-ups-taint";

  meta = {
    description = "Kubernetes manifests for the UPS node taint controller";
    homepage = "https://github.com/josh/kube-ups-taint/tree/main/charts/kube-ups-taint";
    license = lib.licenses.mit;
  };
}
