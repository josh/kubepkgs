{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/goharbor/nginx-photon";
  lock = ./nginx-photon-index.json;

  meta = {
    description = "Harbor nginx container image mirror";
    homepage = "https://goharbor.io";
    license = lib.licenses.bsd2;
  };
}
