{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/tailscale/k8s-operator";
  lock = ./k8s-operator-index.json;

  meta = {
    description = "Tailscale Kubernetes operator container image mirror";
    homepage = "https://tailscale.com/kb/1236/kubernetes-operator";
    license = lib.licenses.bsd3;
  };
}
