{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "kube-state-metrics";
  version = "8.6.0";
  hash = "sha256-6f0ybk5ZeHvr6hHPr/WFuES5bFO/cJJWQFdQM/9tSEU=";

  meta = {
    description = "Helm chart for kube-state-metrics, which generates and exposes cluster-level metrics";
    homepage = "https://github.com/kubernetes/kube-state-metrics";
    license = lib.licenses.asl20;
  };
}
