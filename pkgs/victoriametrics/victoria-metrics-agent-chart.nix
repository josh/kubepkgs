{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-agent";
  version = "0.49.0";
  hash = "sha256-DUgYfBqkT/TejMEJeFHbw0ayL9L4EUBmpn9CiVkKN64=";
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
