{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/victoriametrics/vlagent";
  lock = ./vlagent-index.json;

  meta = {
    description = "VictoriaLogs agent container image mirror";
    homepage = "https://victoriametrics.com";
    license = lib.licenses.asl20;
  };
}
