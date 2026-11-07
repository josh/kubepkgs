{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "quay.io/argoproj/argocd";
  lock = ./argocd-index.json;

  meta = {
    description = "Argo CD container image mirror";
    homepage = "https://argo-cd.readthedocs.io";
    license = lib.licenses.asl20;
  };
}
