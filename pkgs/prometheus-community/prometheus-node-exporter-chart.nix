{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus-node-exporter";
  version = "4.60.0";
  hash = "sha256-bjjUcy8vPh6KmqtBmuc8j8qhCE6to6vNxKL8VByMMe0=";

  meta = {
    description = "Helm chart for the Prometheus node exporter, exposing hardware and OS metrics";
    homepage = "https://github.com/prometheus/node_exporter";
    license = lib.licenses.asl20;
  };
}
