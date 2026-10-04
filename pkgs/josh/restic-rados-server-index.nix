{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/josh/restic-rados-server";
  lock = ./restic-rados-server-index.json;

  meta = {
    description = "restic-rados-server container image mirror";
    homepage = "https://github.com/josh/restic-rados-server";
    license = lib.licenses.mit;
  };
}
