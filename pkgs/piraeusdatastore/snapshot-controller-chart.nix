{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://piraeus.io/helm-charts/";
  chart = "snapshot-controller";
  version = "5.3.0";
  hash = "sha256-FU4qnEI90aRidjgpLYSF1rudD+GmolEld8BjQbvu7GQ=";

  meta = {
    description = "Helm chart deploying a CSI snapshot controller for distributions that do not bundle one";
    homepage = "https://github.com/piraeusdatastore/helm-charts";
    license = lib.licenses.asl20;
  };
}
