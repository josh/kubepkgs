{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/fancybits/channels-dvr";
  lock = ./channels-dvr-index.json;

  meta = {
    description = "Channels DVR server container image mirror";
    homepage = "https://hub.docker.com/r/fancybits/channels-dvr";
    license = lib.licenses.unfree;
  };
}
