{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-logs-cluster";
  version = "0.2.11";
  hash = "sha256-Y7hY702LTl/2lT/4TSVsMTQTnpwY5kqcldd6ECrwax0=";

  meta = {
    description = "Helm chart for deploying a VictoriaLogs cluster database in Kubernetes";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
