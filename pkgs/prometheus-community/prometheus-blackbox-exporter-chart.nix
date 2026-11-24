{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus-blackbox-exporter";
  version = "11.23.0";
  hash = "sha256-YN2kuUphcMHgiGZkWv1dd4i6JfRQp30wG+9zFDMQN8k=";

  meta = {
    description = "Helm chart for the Prometheus blackbox exporter, probing endpoints over HTTP, TCP, DNS and ICMP";
    homepage = "https://github.com/prometheus/blackbox_exporter";
    license = lib.licenses.asl20;
  };
}
