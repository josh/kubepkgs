{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus-blackbox-exporter";
  version = "11.20.2";
  hash = "sha256-al4j8WmIawlBBxq9/T4oECQ0nlDwcSxJ4CECYbyrtuQ=";

  meta = {
    description = "Helm chart for the Prometheus blackbox exporter, probing endpoints over HTTP, TCP, DNS and ICMP";
    homepage = "https://github.com/prometheus/blackbox_exporter";
    license = lib.licenses.asl20;
  };
}
