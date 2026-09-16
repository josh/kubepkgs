{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "victoria-logs-collector-manifests";
  src = kubepkgs.victoria-logs-collector-chart;
  chartName = "victoria-logs-collector";

  helmValues = {
    remoteWrite = [
      { url = "http://victoria-logs:9428"; }
    ];
  };

  meta = {
    description = "Kubernetes manifests for the VictoriaLogs collector, shipping Kubernetes container logs to VictoriaLogs";
    homepage = "https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-logs-collector";
    license = lib.licenses.asl20;
  };
}
