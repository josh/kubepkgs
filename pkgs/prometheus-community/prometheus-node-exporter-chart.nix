{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus-node-exporter";
  version = "5.1.0";
  hash = "sha256-ZUmpjPW3dOpOTGxj7uXrE4j1REa1f0LkkyorVT439sw=";

  meta = {
    description = "Helm chart for the Prometheus node exporter, exposing hardware and OS metrics";
    homepage = "https://github.com/prometheus/node_exporter";
    license = lib.licenses.asl20;
  };
}
