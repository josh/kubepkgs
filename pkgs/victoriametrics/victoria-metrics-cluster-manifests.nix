{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "victoria-metrics-cluster-manifests";
  src = kubepkgs.victoria-metrics-cluster-chart;
  chartName = "victoria-metrics-cluster";

  meta = {
    description = "Kubernetes manifests for a VictoriaMetrics cluster, a time series database and long-term remote storage for Prometheus";
    homepage = "https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-cluster";
    license = lib.licenses.asl20;
  };
}
