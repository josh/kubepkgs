{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/victoriametrics/vmalert";
  lock = ./vmalert-index.json;

  meta = {
    description = "VictoriaMetrics vmalert container image mirror";
    homepage = "https://docs.victoriametrics.com/vmalert/";
    license = lib.licenses.asl20;
  };
}
