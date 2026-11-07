{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/cloudnative-pg/cloudnative-pg";
  lock = ./cloudnative-pg-index.json;

  meta = {
    description = "CloudNativePG operator container image mirror";
    homepage = "https://cloudnative-pg.io";
    license = lib.licenses.asl20;
  };
}
