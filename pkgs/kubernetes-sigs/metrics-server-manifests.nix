{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "metrics-server-manifests";
  src = kubepkgs.metrics-server-chart;
  chartName = "metrics-server";

  meta = {
    description = "Kubernetes manifests for Metrics Server, a source of container resource metrics for Kubernetes autoscaling";
    homepage = "https://github.com/kubernetes-sigs/metrics-server";
    license = lib.licenses.asl20;
  };
}
