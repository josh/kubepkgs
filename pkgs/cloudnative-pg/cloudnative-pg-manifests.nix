{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "cloudnative-pg-manifests";
  src = kubepkgs.cloudnative-pg-chart;
  chartName = "cloudnative-pg";

  meta = {
    description = "Kubernetes manifests for the CloudNativePG operator";
    homepage = "https://cloudnative-pg.io";
    license = lib.licenses.asl20;
  };
}
