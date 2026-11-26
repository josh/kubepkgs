{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/usekaneo/kaneo";
  lock = ./kaneo-index.json;

  meta = {
    description = "Kaneo container image mirror";
    homepage = "https://kaneo.app";
    license = lib.licenses.mit;
  };
}
