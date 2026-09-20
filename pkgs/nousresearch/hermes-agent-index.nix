{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/nousresearch/hermes-agent";
  lock = ./hermes-agent-index.json;

  meta = {
    description = "Hermes agent container image mirror";
    homepage = "https://hub.docker.com/r/nousresearch/hermes-agent";
    license = lib.licenses.mit;
  };
}
