{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://nats-io.github.io/k8s/helm/charts";
  chart = "nats";
  version = "2.15.3";
  hash = "sha256-q1wql6WC1/zSEPrpBkNMBsACKkbGMx/uEyyG9Upnqmc=";

  meta = {
    description = "Helm chart for NATS, a cloud native messaging system";
    homepage = "https://github.com/nats-io/k8s";
    license = lib.licenses.asl20;
  };
}
