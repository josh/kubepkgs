{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/goharbor/registry-photon";
  lock = ./registry-photon-index.json;

  meta = {
    description = "Harbor registry container image mirror";
    homepage = "https://goharbor.io";
    license = lib.licenses.asl20;
  };
}
