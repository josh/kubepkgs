{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://grafana-community.github.io/helm-charts";
  chart = "grafana";
  version = "14.3.0";
  hash = "sha256-yO6Ot9YVhbpdp5e3DdQOlDmqFfEd28H4c/+IUlGpBKU=";

  meta = {
    description = "Helm chart for Grafana, a tool for querying and visualizing time series and metrics";
    homepage = "https://grafana.com";
    license = lib.licenses.asl20;
  };
}
