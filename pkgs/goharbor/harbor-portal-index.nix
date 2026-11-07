{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/goharbor/harbor-portal";
  lock = ./harbor-portal-index.json;

  meta = {
    description = "Harbor portal container image mirror";
    homepage = "https://goharbor.io";
    license = lib.licenses.asl20;
  };
}
