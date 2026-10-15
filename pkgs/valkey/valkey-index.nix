{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/valkey/valkey";
  lock = ./valkey-index.json;
  # MAJOR.MINOR tags like 9.2 float onto release candidates before 9.2.0 exists,
  # and would otherwise parse as a newer version than the pinned release.
  tagPattern = "[0-9]+\\.[0-9]+\\.[0-9]+";

  meta = {
    description = "Valkey container image mirror";
    homepage = "https://valkey.io";
    license = lib.licenses.bsd3;
  };
}
