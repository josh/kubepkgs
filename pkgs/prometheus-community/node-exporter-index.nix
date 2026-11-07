{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "quay.io/prometheus/node-exporter";
  lock = ./node-exporter-index.json;

  meta = {
    description = "Prometheus node exporter container image mirror";
    homepage = "https://github.com/prometheus/node_exporter";
    license = lib.licenses.asl20;
  };
}
