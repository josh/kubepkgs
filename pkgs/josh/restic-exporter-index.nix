{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/josh/restic-exporter";
  lock = ./restic-exporter-index.json;

  meta = {
    description = "restic-exporter container image mirror";
    homepage = "https://github.com/josh/restic-exporter";
    license = lib.licenses.mit;
  };
}
