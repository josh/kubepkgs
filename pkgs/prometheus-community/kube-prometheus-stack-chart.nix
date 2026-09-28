{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "kube-prometheus-stack";
  version = "91.8.1";
  hash = "sha256-YyCoqI7DwEbgtU8XsIffU+GLi7pi+T21Co5mzFaMgEk=";

  crds.file = ../../crds/kube-prometheus-stack.nix;

  meta = {
    description = "Helm chart for end-to-end Kubernetes cluster monitoring with Prometheus, Grafana, and the Prometheus Operator";
    homepage = "https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack";
    license = lib.licenses.asl20;
  };
}
