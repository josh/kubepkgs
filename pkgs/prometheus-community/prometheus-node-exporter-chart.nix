{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus-node-exporter";
  version = "6.0.0";
  hash = "sha256-nIKCl1Rp0LOjjT0IFJCZJ00JOh0Dv2/0eYBc0eDddC8=";

  meta = {
    description = "Helm chart for the Prometheus node exporter, exposing hardware and OS metrics";
    homepage = "https://github.com/prometheus/node_exporter";
    license = lib.licenses.asl20;
  };
}
