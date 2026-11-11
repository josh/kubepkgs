{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus-blackbox-exporter";
  version = "11.21.2";
  hash = "sha256-KQbtYPxEUW6SbWMXSLUm96YsRDu2WHFjNS2Xn9GmIe8=";

  meta = {
    description = "Helm chart for the Prometheus blackbox exporter, probing endpoints over HTTP, TCP, DNS and ICMP";
    homepage = "https://github.com/prometheus/blackbox_exporter";
    license = lib.licenses.asl20;
  };
}
