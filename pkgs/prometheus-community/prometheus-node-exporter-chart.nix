{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus-node-exporter";
  version = "5.0.1";
  hash = "sha256-efVvaYMKdUzfLD+uSSvYaWCnNQq6wUBW7/9iN70Uw+k=";

  meta = {
    description = "Helm chart for the Prometheus node exporter, exposing hardware and OS metrics";
    homepage = "https://github.com/prometheus/node_exporter";
    license = lib.licenses.asl20;
  };
}
