{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-logs-collector";
  version = "0.3.9";
  hash = "sha256-zq+dO/DtAYiWhHCB9zlN6qPr3+JNADDSzFKGrjgq2zc=";
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
