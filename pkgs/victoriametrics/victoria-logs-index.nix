{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/victoriametrics/victoria-logs";
  lock = ./victoria-logs-index.json;

  meta = {
    description = "VictoriaLogs container image mirror";
    homepage = "https://victoriametrics.com";
    license = lib.licenses.asl20;
  };
}
