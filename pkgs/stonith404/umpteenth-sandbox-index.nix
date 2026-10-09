{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/stonith404/umpteenth-sandbox";
  lock = ./umpteenth-sandbox-index.json;

  meta = {
    description = "Umpteenth sandbox container image mirror";
    homepage = "https://umpteenth.dev";
    license = lib.licenses.agpl3Only;
  };
}
