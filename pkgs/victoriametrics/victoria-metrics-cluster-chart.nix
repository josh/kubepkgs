{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-cluster";
  version = "0.51.0";
  hash = "sha256-e+fWw4RwODZFSGtlmlWEiHfWf01BwCVRuG00NjBvILc=";

  meta = {
    description = "Helm chart for a VictoriaMetrics cluster, a time series database and long-term remote storage for Prometheus";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
