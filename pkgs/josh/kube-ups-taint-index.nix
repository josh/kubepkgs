{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/josh/kube-ups-taint";
  lock = ./kube-ups-taint-index.json;

  meta = {
    description = "kube-ups-taint container image mirror";
    homepage = "https://github.com/josh/kube-ups-taint";
    license = lib.licenses.mit;
  };
}
