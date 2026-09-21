{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://nats-io.github.io/k8s/helm/charts";
  chart = "nats";
  version = "2.15.0";
  hash = "sha256-FVs3+upM8dhG+hN5AIaxql3KaSdkNScEsS4gJ7DWzC0=";

  meta = {
    description = "Helm chart for NATS, a cloud native messaging system";
    homepage = "https://github.com/nats-io/k8s";
    license = lib.licenses.asl20;
  };
}
