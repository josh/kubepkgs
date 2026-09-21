{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-k8s-stack";
  version = "0.93.0";
  hash = "sha256-C3joplBAk1Gb48wWLXHeghyoRwxdwK7VFHGWdbWdQJk=";

  meta = {
    description = "Helm chart for Kubernetes monitoring with the VictoriaMetrics operator, Grafana dashboards, ServiceScrapes and VMRules";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
