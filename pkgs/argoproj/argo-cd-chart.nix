{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://argoproj.github.io/argo-helm/";
  chart = "argo-cd";
  version = "10.11.7";
  hash = "sha256-awfYdS5p2ERJ7JLyO4t4i2Eo6O49F7VCHZ4EHsuRb4c=";

  crds.file = ../../crds/argo-cd.nix;

  meta = {
    description = "Helm chart for Argo CD, a declarative GitOps continuous delivery tool for Kubernetes";
    homepage = "https://github.com/argoproj/argo-helm";
    license = lib.licenses.asl20;
  };
}
