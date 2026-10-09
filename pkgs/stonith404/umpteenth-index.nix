{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/stonith404/umpteenth";
  lock = ./umpteenth-index.json;

  meta = {
    description = "Umpteenth container image mirror";
    homepage = "https://umpteenth.dev";
    license = lib.licenses.agpl3Only;
  };
}
