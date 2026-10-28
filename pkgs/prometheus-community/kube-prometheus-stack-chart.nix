{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "kube-prometheus-stack";
  version = "92.14.1";
  hash = "sha256-3YnhOd8uAjE1L9CXCYWD06tsxRkYZPS/rYoEk2UgZ+U=";

  crds.file = ../../crds/kube-prometheus-stack.nix;

  meta = {
    description = "Helm chart for end-to-end Kubernetes cluster monitoring with Prometheus, Grafana, and the Prometheus Operator";
    homepage = "https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack";
    license = lib.licenses.asl20;
  };
}
