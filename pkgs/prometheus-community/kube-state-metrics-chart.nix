{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "kube-state-metrics";
  version = "8.8.0";
  hash = "sha256-38Xj9EJtTDwtvXNqDJLkFsg5+YkGjiT45KYVhh/MHpw=";

  meta = {
    description = "Helm chart for kube-state-metrics, which generates and exposes cluster-level metrics";
    homepage = "https://github.com/kubernetes/kube-state-metrics";
    license = lib.licenses.asl20;
  };
}
