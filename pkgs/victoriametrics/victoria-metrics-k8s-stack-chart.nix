{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-k8s-stack";
  version = "0.96.0";
  hash = "sha256-wesVPJxkB50HIf9YzLi8zOEgfMmta0hJX4n9D9QMHjI=";

  crds.file = ../../crds/victoria-metrics-k8s-stack.nix;

  meta = {
    description = "Helm chart for Kubernetes monitoring with the VictoriaMetrics operator, Grafana dashboards, ServiceScrapes and VMRules";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
