{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/josh/mqtt2nats";
  lock = ./mqtt2nats-index.json;

  meta = {
    description = "mqtt2nats container image mirror";
    homepage = "https://github.com/josh/mqtt2nats";
    license = lib.licenses.mit;
  };
}
