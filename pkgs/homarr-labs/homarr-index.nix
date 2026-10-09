{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/homarr-labs/homarr";
  lock = ./homarr-index.json;

  meta = {
    description = "Homarr container image mirror";
    homepage = "https://homarr.dev";
    license = lib.licenses.asl20;
  };
}
