{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "haproxy-alpine-index";
  imageName = "docker.io/library/haproxy";
  lock = ./haproxy-alpine-index.json;

  meta = {
    description = "HAProxy container image mirror, Alpine variant";
    homepage = "https://hub.docker.com/_/haproxy";
    license = lib.licenses.gpl2Plus;
  };
}
