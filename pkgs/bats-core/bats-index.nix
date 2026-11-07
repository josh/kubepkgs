{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/bats/bats";
  lock = ./bats-index.json;

  meta = {
    description = "Bats container image mirror";
    homepage = "https://github.com/bats-core/bats-core";
    license = lib.licenses.mit;
  };
}
