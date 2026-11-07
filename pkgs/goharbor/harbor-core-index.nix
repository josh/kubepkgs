{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/goharbor/harbor-core";
  lock = ./harbor-core-index.json;

  meta = {
    description = "Harbor core container image mirror";
    homepage = "https://goharbor.io";
    license = lib.licenses.asl20;
  };
}
