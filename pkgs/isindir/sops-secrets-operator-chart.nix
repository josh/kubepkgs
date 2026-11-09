{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://isindir.github.io/sops-secrets-operator/";
  chart = "sops-secrets-operator";
  version = "0.29.2";
  hash = "sha256-jxPGoqjKpk8IrVTM2A38S7PDTaXdujQbp3krpFjAnRU=";

  crds.file = ../../crds/sops-secrets-operator.nix;
  helmTestArgs = [
    "--kube-version"
    "1.36.0"
  ];

  meta = {
    description = "Helm chart for the sops secrets operator, decrypting sops-encrypted Kubernetes secrets";
    homepage = "https://github.com/isindir/sops-secrets-operator";
    license = lib.licenses.mpl20;
  };
}
