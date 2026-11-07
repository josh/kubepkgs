{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/victoriametrics/vmagent";
  lock = ./vmagent-index.json;

  meta = {
    description = "vmagent container image mirror";
    homepage = "https://victoriametrics.com";
    license = lib.licenses.asl20;
  };
}
