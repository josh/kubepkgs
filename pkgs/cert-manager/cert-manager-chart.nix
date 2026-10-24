{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://quay.io/jetstack/charts/cert-manager";
  chart = "cert-manager";
  version = "1.21.3";
  hash = "sha256-kjGAYWkePhiNrUUdpesTcGa9jlpFk1/gZs8sztLElRw=";

  crds = {
    file = ../../crds/cert-manager.nix;
    values.crds.enabled = true;
  };

  meta = {
    description = "Helm chart for cert-manager, automating TLS certificate management on Kubernetes";
    homepage = "https://cert-manager.io";
    license = lib.licenses.asl20;
  };
}
