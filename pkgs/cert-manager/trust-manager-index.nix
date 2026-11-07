{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "quay.io/jetstack/trust-manager";
  lock = ./trust-manager-index.json;

  meta = {
    description = "trust-manager container image mirror";
    homepage = "https://cert-manager.io/docs/trust/trust-manager/";
    license = lib.licenses.asl20;
  };
}
