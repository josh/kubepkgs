{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus";
  version = "31.0.0";
  hash = "sha256-peTnpzFB65k7RT4FgBhy23WzwTeeOflgubLcQaOPZEM=";

  meta = {
    description = "Helm chart for Prometheus, a monitoring system and time series database";
    homepage = "https://prometheus.io";
    license = lib.licenses.asl20;
  };
}
