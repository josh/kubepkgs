{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/josh/nats-static";
  lock = ./nats-static-index.json;

  meta = {
    description = "nats-static container image mirror";
    homepage = "https://github.com/josh/nats-static";
    license = lib.licenses.mit;
  };
}
