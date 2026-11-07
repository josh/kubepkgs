{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "quay.io/isindir/sops-secrets-operator";
  lock = ./sops-secrets-operator-index.json;

  meta = {
    description = "SOPS secrets operator container image mirror";
    homepage = "https://github.com/isindir/sops-secrets-operator";
    license = lib.licenses.asl20;
  };
}
