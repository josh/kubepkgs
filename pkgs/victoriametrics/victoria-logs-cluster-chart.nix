{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-logs-cluster";
  version = "0.2.13";
  hash = "sha256-7gjBRiXazIPWrljQP/x5lL5odDo4Ib8XYIrgG+WV0aY=";

  meta = {
    description = "Helm chart for deploying a VictoriaLogs cluster database in Kubernetes";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
