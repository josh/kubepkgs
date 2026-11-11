{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://isindir.github.io/sops-secrets-operator/";
  chart = "sops-secrets-operator";
  version = "0.29.3";
  hash = "sha256-QP5lAPih3925WizRK+Fug+0CarPttIRET58dT9QeEe0=";

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
