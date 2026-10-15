{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/grafana/grafana";
  lock = ./grafana-index.json;
  # Releases are MAJOR.MINOR.PATCH, but a stray CI run ID tag like 9799770991
  # is also published and would otherwise parse as a newer major.
  tagPattern = "[0-9]+\\.[0-9]+\\.[0-9]+";

  meta = {
    description = "Grafana container image mirror";
    homepage = "https://grafana.com";
    license = lib.licenses.asl20;
  };
}
