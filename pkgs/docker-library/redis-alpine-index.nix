{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "redis-alpine-index";
  imageName = "docker.io/library/redis";
  lock = ./redis-alpine-index.json;

  meta = {
    description = "Redis container image mirror, Alpine variant";
    homepage = "https://hub.docker.com/_/redis";
    license = lib.licenses.bsd3;
  };
}
