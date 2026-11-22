{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "kube-prometheus-stack";
  version = "93.9.0";
  hash = "sha256-edcfqWEDUm8AX7yf6zD2UOywDxmync9hnReKgk27+ts=";

  crds.file = ../../crds/kube-prometheus-stack.nix;

  meta = {
    description = "Helm chart for end-to-end Kubernetes cluster monitoring with Prometheus, Grafana, and the Prometheus Operator";
    homepage = "https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack";
    license = lib.licenses.asl20;
  };
}
