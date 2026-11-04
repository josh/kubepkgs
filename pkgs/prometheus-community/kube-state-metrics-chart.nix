{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "kube-state-metrics";
  version = "9.0.0";
  hash = "sha256-gpJFaSRtn4SCFlgRUTXYXQJZAxf3xBoQWzwywDGsEbI=";

  meta = {
    description = "Helm chart for kube-state-metrics, which generates and exposes cluster-level metrics";
    homepage = "https://github.com/kubernetes/kube-state-metrics";
    license = lib.licenses.asl20;
  };
}
