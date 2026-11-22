{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus-blackbox-exporter";
  version = "11.22.0";
  hash = "sha256-nZo+bMUabCnc43EwPYa/y7h60hRm2JFunxqdDDAwKjk=";

  meta = {
    description = "Helm chart for the Prometheus blackbox exporter, probing endpoints over HTTP, TCP, DNS and ICMP";
    homepage = "https://github.com/prometheus/blackbox_exporter";
    license = lib.licenses.asl20;
  };
}
