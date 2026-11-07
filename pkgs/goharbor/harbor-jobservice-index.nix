{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/goharbor/harbor-jobservice";
  lock = ./harbor-jobservice-index.json;

  meta = {
    description = "Harbor jobservice container image mirror";
    homepage = "https://goharbor.io";
    license = lib.licenses.asl20;
  };
}
