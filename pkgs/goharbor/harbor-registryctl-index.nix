{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/goharbor/harbor-registryctl";
  lock = ./harbor-registryctl-index.json;

  meta = {
    description = "Harbor registryctl container image mirror";
    homepage = "https://goharbor.io";
    license = lib.licenses.asl20;
  };
}
