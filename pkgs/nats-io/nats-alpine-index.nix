{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "nats-alpine-index";
  imageName = "docker.io/library/nats";
  lock = ./nats-alpine-index.json;

  meta = {
    description = "NATS server container image mirror, Alpine variant";
    homepage = "https://hub.docker.com/_/nats";
    license = lib.licenses.asl20;
  };
}
