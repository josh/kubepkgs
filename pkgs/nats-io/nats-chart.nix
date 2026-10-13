{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://nats-io.github.io/k8s/helm/charts";
  chart = "nats";
  version = "2.15.1";
  hash = "sha256-6S2pBF6PkFMwnWVAz3Gb6zXAo/4N/071A46b5kZ+Ezo=";

  meta = {
    description = "Helm chart for NATS, a cloud native messaging system";
    homepage = "https://github.com/nats-io/k8s";
    license = lib.licenses.asl20;
  };
}
