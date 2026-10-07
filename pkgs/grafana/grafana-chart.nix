{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://grafana-community.github.io/helm-charts";
  chart = "grafana";
  version = "13.3.1";
  hash = "sha256-JEFU11/juB1/3B/vpy8ENqwCrZ9H4itGnnfnKaCe2gQ=";

  meta = {
    description = "Helm chart for Grafana, a tool for querying and visualizing time series and metrics";
    homepage = "https://grafana.com";
    license = lib.licenses.asl20;
  };
}
