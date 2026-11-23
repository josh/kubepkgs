{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-cluster";
  version = "0.56.0";
  hash = "sha256-0sSk/FyC621A46qJdR0OXMqUot8LAew7FNOS700ga0k=";

  meta = {
    description = "Helm chart for a VictoriaMetrics cluster, a time series database and long-term remote storage for Prometheus";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
