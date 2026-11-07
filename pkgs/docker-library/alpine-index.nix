{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/library/alpine";
  lock = ./alpine-index.json;
  # Date-stamped edge snapshots like 20260805 are also published and would
  # otherwise parse as a newer major.
  tagPattern = "[0-9]+\\.[0-9]+(\\.[0-9]+)?";

  meta = {
    description = "Alpine Linux container image mirror";
    homepage = "https://hub.docker.com/_/alpine";
    license = lib.licenses.mit;
  };
}
