{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://nats-io.github.io/k8s/helm/charts";
  chart = "nack";
  version = "0.36.0";
  hash = "sha256-RJNBykDyxeWXg1VMn7aucG0ea5gcG8MLDvOzxzM1PRg=";

  crds.file = ../../crds/nack.nix;

  meta = {
    description = "Helm chart for NACK, the NATS controller for Kubernetes";
    homepage = "https://github.com/nats-io/k8s";
    license = lib.licenses.asl20;
  };
}
