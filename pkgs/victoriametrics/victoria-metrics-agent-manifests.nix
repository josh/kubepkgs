{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "victoria-metrics-agent-manifests";
  src = kubepkgs.victoria-metrics-agent-chart;
  chartName = "victoria-metrics-agent";

  helmValues = {
    remoteWrite = [
      { url = "http://victoria-metrics:8428"; }
    ];
  };

  meta = {
    description = "Kubernetes manifests for the VictoriaMetrics agent, collecting metrics and forwarding them to VictoriaMetrics";
    homepage = "https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-agent";
    license = lib.licenses.asl20;
  };
}
