{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "registry.k8s.io/descheduler/descheduler";
  lock = ./descheduler-index.json;

  meta = {
    description = "Descheduler container image mirror";
    homepage = "https://github.com/kubernetes-sigs/descheduler";
    license = lib.licenses.asl20;
  };
}
