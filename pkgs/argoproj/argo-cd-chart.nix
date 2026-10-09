{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://argoproj.github.io/argo-helm/";
  chart = "argo-cd";
  version = "10.10.2";
  hash = "sha256-39IWj0TeK3fQuuLX66YwPBTMhGl++j8G2N6/5fbIHyg=";

  crds.file = ../../crds/argo-cd.nix;

  meta = {
    description = "Helm chart for Argo CD, a declarative GitOps continuous delivery tool for Kubernetes";
    homepage = "https://github.com/argoproj/argo-helm";
    license = lib.licenses.asl20;
  };
}
