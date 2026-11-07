{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/goharbor/harbor-exporter";
  lock = ./harbor-exporter-index.json;

  meta = {
    description = "Harbor exporter container image mirror";
    homepage = "https://goharbor.io";
    license = lib.licenses.asl20;
  };
}
