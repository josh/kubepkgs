{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/grafana/grafana-operator";
  lock = ./grafana-operator-index.json;

  meta = {
    description = "Grafana Operator container image mirror";
    homepage = "https://github.com/grafana/grafana-operator";
    license = lib.licenses.asl20;
  };
}
