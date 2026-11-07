{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/goharbor/valkey-photon";
  lock = ./valkey-photon-index.json;

  meta = {
    description = "Harbor Valkey container image mirror";
    homepage = "https://goharbor.io";
    license = lib.licenses.bsd3;
  };
}
