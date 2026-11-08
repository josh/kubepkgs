{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus";
  version = "29.45.1";
  hash = "sha256-S5xuiGLKPHKTGlb4sgbBZLNDh0JAZaooy6Q9m3odDIE=";

  meta = {
    description = "Helm chart for Prometheus, a monitoring system and time series database";
    homepage = "https://prometheus.io";
    license = lib.licenses.asl20;
  };
}
