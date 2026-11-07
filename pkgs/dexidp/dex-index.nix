{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/dexidp/dex";
  lock = ./dex-index.json;

  meta = {
    description = "Dex container image mirror";
    homepage = "https://dexidp.io";
    license = lib.licenses.asl20;
  };
}
