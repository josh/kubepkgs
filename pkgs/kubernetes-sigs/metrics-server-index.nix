{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "registry.k8s.io/metrics-server/metrics-server";
  lock = ./metrics-server-index.json;

  meta = {
    description = "Metrics Server container image mirror";
    homepage = "https://github.com/kubernetes-sigs/metrics-server";
    license = lib.licenses.asl20;
  };
}
