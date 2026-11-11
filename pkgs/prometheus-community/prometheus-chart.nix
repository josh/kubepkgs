{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus";
  version = "29.47.2";
  hash = "sha256-6ro1K+ryqrNyo4uq2BQJ/BMVVfSsDSHRuWd5/dZ1gr4=";

  meta = {
    description = "Helm chart for Prometheus, a monitoring system and time series database";
    homepage = "https://prometheus.io";
    license = lib.licenses.asl20;
  };
}
