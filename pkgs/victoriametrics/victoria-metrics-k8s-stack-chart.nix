{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-k8s-stack";
  version = "0.96.1";
  hash = "sha256-8KcQdlmKl0VDZRRdAq+meDIwrF9AHbSkl7vdD07lPXc=";

  crds.file = ../../crds/victoria-metrics-k8s-stack.nix;

  meta = {
    description = "Helm chart for Kubernetes monitoring with the VictoriaMetrics operator, Grafana dashboards, ServiceScrapes and VMRules";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
