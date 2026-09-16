{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "gitea-manifests";
  src = kubepkgs.gitea-chart;
  chartName = "gitea";

  meta = {
    description = "Kubernetes manifests for Gitea, a self-hosted Git service";
    homepage = "https://gitea.com/gitea/helm-gitea";
    license = lib.licenses.mit;
  };
}
