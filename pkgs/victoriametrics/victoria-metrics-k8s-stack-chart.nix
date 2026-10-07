{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-k8s-stack";
  version = "0.95.2";
  hash = "sha256-Xi7TYFUfYi2X5cEe/Q2eTqnJi6gw9Fz6QveWV9Q6C88=";

  crds.file = ../../crds/victoria-metrics-k8s-stack.nix;

  meta = {
    description = "Helm chart for Kubernetes monitoring with the VictoriaMetrics operator, Grafana dashboards, ServiceScrapes and VMRules";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
