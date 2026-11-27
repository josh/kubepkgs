{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-logs-collector";
  version = "0.3.10";
  hash = "sha256-O4efAhosFi1C3CmQDSaqhnjHXqAhoZGS49m8PI4/SGk=";
  helmTestValues = {
    remoteWrite = [
      { url = "http://victoria-logs:9428"; }
    ];
  };

  meta = {
    description = "Helm chart for the VictoriaLogs collector, shipping Kubernetes container logs to VictoriaLogs";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
