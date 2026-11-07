{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://argoproj.github.io/argo-helm/";
  chart = "argo-cd";
  version = "10.15.0";
  hash = "sha256-YRPx1RJYnF8UUmbgO1dbCjNtS9k7RlXGw5sh78Qwa0w=";

  crds.file = ../../crds/argo-cd.nix;

  meta = {
    description = "Helm chart for Argo CD, a declarative GitOps continuous delivery tool for Kubernetes";
    homepage = "https://github.com/argoproj/argo-helm";
    license = lib.licenses.asl20;
  };
}
