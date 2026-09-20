{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/library/busybox";
  lock = ./busybox-index.json;

  meta = {
    description = "BusyBox container image mirror";
    homepage = "https://hub.docker.com/_/busybox";
    license = lib.licenses.gpl2Only;
  };
}
