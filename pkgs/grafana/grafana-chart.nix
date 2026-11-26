{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://grafana-community.github.io/helm-charts";
  chart = "grafana";
  version = "14.6.1";
  hash = "sha256-BJiczsR3wSfcKiy5R3kJP/1Ja+1sk6XOa3QRAnMNW/c=";

  meta = {
    description = "Helm chart for Grafana, a tool for querying and visualizing time series and metrics";
    homepage = "https://grafana.com";
    license = lib.licenses.asl20;
  };
}
