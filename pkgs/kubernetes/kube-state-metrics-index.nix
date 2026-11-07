{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "registry.k8s.io/kube-state-metrics/kube-state-metrics";
  lock = ./kube-state-metrics-index.json;

  meta = {
    description = "kube-state-metrics container image mirror";
    homepage = "https://github.com/kubernetes/kube-state-metrics";
    license = lib.licenses.asl20;
  };
}
