{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://argoproj.github.io/argo-helm/";
  chart = "argo-cd";
  version = "10.17.1";
  hash = "sha256-lANZlSwde4yVWWny7rsYqBOpU+RLljSX8e9JnBATAA8=";

  crds.file = ../../crds/argo-cd.nix;

  meta = {
    description = "Helm chart for Argo CD, a declarative GitOps continuous delivery tool for Kubernetes";
    homepage = "https://github.com/argoproj/argo-helm";
    license = lib.licenses.asl20;
  };
}
