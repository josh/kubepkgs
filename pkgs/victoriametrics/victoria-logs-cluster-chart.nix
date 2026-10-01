{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-logs-cluster";
  version = "0.2.9";
  hash = "sha256-kjl+Qhp4ORiuvbgDxy6jdwbi33YX2oqXE9ARLLdFhaI=";

  meta = {
    description = "Helm chart for deploying a VictoriaLogs cluster database in Kubernetes";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
