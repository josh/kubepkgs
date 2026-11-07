{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "kube-prometheus-stack";
  version = "92.22.0";
  hash = "sha256-HzvVeK1FZnT7iMYhHlXi/f4IXl/teomYgqp7rZE486A=";

  crds.file = ../../crds/kube-prometheus-stack.nix;

  meta = {
    description = "Helm chart for end-to-end Kubernetes cluster monitoring with Prometheus, Grafana, and the Prometheus Operator";
    homepage = "https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack";
    license = lib.licenses.asl20;
  };
}
