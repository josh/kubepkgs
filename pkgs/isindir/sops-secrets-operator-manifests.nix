{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "sops-secrets-operator-manifests";
  src = kubepkgs.sops-secrets-operator-chart;
  chartName = "sops-secrets-operator";

  helmArgs = [
    "--kube-version"
    "1.36.0"
  ];

  meta = {
    description = "Kubernetes manifests for the sops secrets operator, decrypting sops-encrypted Kubernetes secrets";
    homepage = "https://github.com/isindir/sops-secrets-operator/tree/master/chart/helm4/sops-secrets-operator";
    license = lib.licenses.mpl20;
  };
}
