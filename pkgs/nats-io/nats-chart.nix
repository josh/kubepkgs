{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://nats-io.github.io/k8s/helm/charts";
  chart = "nats";
  version = "2.15.2";
  hash = "sha256-ECXTlREkYME8+D0qOidd+I/cBauw1enz9oUFuyF4E2k=";

  meta = {
    description = "Helm chart for NATS, a cloud native messaging system";
    homepage = "https://github.com/nats-io/k8s";
    license = lib.licenses.asl20;
  };
}
