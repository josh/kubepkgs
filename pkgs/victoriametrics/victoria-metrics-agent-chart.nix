{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-agent";
  version = "0.48.0";
  hash = "sha256-5O+kg7J7M7kMuFNpLbQCGOtu2L2PfA54IXmwFEIBfOY=";
  helmTestValues = {
    remoteWrite = [
      { url = "http://victoria-metrics:8428"; }
    ];
  };

  meta = {
    description = "Helm chart for the VictoriaMetrics agent, collecting metrics and forwarding them to VictoriaMetrics";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
