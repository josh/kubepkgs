{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://piraeus.io/helm-charts/";
  chart = "snapshot-controller";
  version = "5.4.1";
  hash = "sha256-kzQzhfZQJB0X1lE+LwLuhrLnidVBSAprWdn8rmenKQM=";

  crds.file = ../../crds/snapshot-controller.nix;

  meta = {
    description = "Helm chart deploying a CSI snapshot controller for distributions that do not bundle one";
    homepage = "https://github.com/piraeusdatastore/helm-charts";
    license = lib.licenses.asl20;
  };
}
