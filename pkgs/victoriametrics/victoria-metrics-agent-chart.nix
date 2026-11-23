{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-agent";
  version = "0.53.0";
  hash = "sha256-jqqQbByCDyGpB7sVaE/gzWrdKi0QEG6nuV4LpzwQZ5Q=";
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
