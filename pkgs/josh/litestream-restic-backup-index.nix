{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/josh/litestream-restic-backup";
  lock = ./litestream-restic-backup-index.json;

  meta = {
    description = "litestream-restic-backup container image mirror";
    homepage = "https://github.com/josh/litestream-restic-backup";
    license = lib.licenses.mit;
  };
}
