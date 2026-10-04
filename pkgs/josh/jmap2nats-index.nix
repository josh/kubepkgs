{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/josh/jmap2nats";
  lock = ./jmap2nats-index.json;

  meta = {
    description = "jmap2nats container image mirror";
    homepage = "https://github.com/josh/jmap2nats";
    license = lib.licenses.mit;
  };
}
