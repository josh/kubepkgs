{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "victoria-logs-cluster-manifests";
  src = kubepkgs.victoria-logs-cluster-chart;
  chartName = "victoria-logs-cluster";

  meta = {
    description = "Kubernetes manifests for a VictoriaLogs cluster database";
    homepage = "https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-logs-cluster";
    license = lib.licenses.asl20;
  };
}
