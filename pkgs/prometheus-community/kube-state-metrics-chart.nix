{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "kube-state-metrics";
  version = "9.1.0";
  hash = "sha256-0CgdNEn0D2D+6I8/+HrUqYGsJnCJv7y4ihLqCwz6bFo=";

  meta = {
    description = "Helm chart for kube-state-metrics, which generates and exposes cluster-level metrics";
    homepage = "https://github.com/kubernetes/kube-state-metrics";
    license = lib.licenses.asl20;
  };
}
