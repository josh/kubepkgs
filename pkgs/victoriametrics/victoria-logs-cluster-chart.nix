{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-logs-cluster";
  version = "0.2.12";
  hash = "sha256-wtKvOchgirrKFDBv541CMKpTI/Eo1TNKg1CrxPrh3H0=";

  meta = {
    description = "Helm chart for deploying a VictoriaLogs cluster database in Kubernetes";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
