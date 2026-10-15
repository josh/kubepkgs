{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "valkey-alpine-index";
  imageName = "docker.io/valkey/valkey";
  lock = ./valkey-alpine-index.json;
  # MAJOR.MINOR tags like 9.2-alpine float onto release candidates before
  # 9.2.0-alpine exists, and would otherwise parse as a newer version.
  tagPattern = "[0-9]+\\.[0-9]+\\.[0-9]+-alpine";

  meta = {
    description = "Valkey container image mirror, Alpine variant";
    homepage = "https://valkey.io";
    license = lib.licenses.bsd3;
  };
}
