{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://argoproj.github.io/argo-helm/";
  chart = "argo-cd";
  version = "10.18.0";
  hash = "sha256-EATFNijP8ls/KOexP6AFxcpya5JPP9sjF8rjMed2fBQ=";

  crds.file = ../../crds/argo-cd.nix;

  meta = {
    description = "Helm chart for Argo CD, a declarative GitOps continuous delivery tool for Kubernetes";
    homepage = "https://github.com/argoproj/argo-helm";
    license = lib.licenses.asl20;
  };
}
