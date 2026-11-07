{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/tailscale/k8s-nameserver";
  lock = ./k8s-nameserver-index.json;

  meta = {
    description = "Tailscale Kubernetes nameserver container image mirror";
    homepage = "https://tailscale.com/kb/1236/kubernetes-operator";
    license = lib.licenses.bsd3;
  };
}
