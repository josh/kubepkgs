{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-cluster";
  version = "0.54.0";
  hash = "sha256-hKHnrfLZUztuSRWVQQ2s3e9xIEURnEXX70k2LpMqEI8=";

  meta = {
    description = "Helm chart for a VictoriaMetrics cluster, a time series database and long-term remote storage for Prometheus";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
