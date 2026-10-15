{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/jellyfin/jellyfin";
  lock = ./jellyfin-index.json;
  # Stable releases are MAJOR.MINOR; nightlies are bare dates like 2026101212,
  # which would otherwise parse as a newer major.
  tagPattern = "[0-9]+\\.[0-9]+";

  meta = {
    description = "Jellyfin container image mirror";
    homepage = "https://jellyfin.org";
    license = lib.licenses.gpl2Only;
  };
}
