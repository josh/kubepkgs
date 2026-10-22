{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://prometheus-community.github.io/helm-charts";
  chart = "prometheus";
  version = "29.37.1";
  hash = "sha256-OOLZiif9hVf5COonuG/6Yu7qrPMbOoJi5aT7QhP2dmY=";

  meta = {
    description = "Helm chart for Prometheus, a monitoring system and time series database";
    homepage = "https://prometheus.io";
    license = lib.licenses.asl20;
  };
}
