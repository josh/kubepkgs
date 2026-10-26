{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://grafana-community.github.io/helm-charts";
  chart = "grafana";
  version = "14.1.0";
  hash = "sha256-iKN7ofT+BSD0kxshyQ+vnqfb6psPM5vQhKLQaAXfnnQ=";

  meta = {
    description = "Helm chart for Grafana, a tool for querying and visualizing time series and metrics";
    homepage = "https://grafana.com";
    license = lib.licenses.asl20;
  };
}
