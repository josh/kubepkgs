{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "gha-runner-scale-set-controller-manifests";
  src = kubepkgs.gha-runner-scale-set-controller-chart;
  chartName = "gha-runner-scale-set-controller";

  meta = {
    description = "Kubernetes manifests for the GitHub Actions runner scale set controller";
    homepage = "https://github.com/actions/actions-runner-controller";
    license = lib.licenses.asl20;
  };
}
