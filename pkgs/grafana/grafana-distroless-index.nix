{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "grafana-distroless-index";
  imageName = "docker.io/grafana/grafana";
  lock = ./grafana-distroless-index.json;

  meta = {
    description = "Grafana container image mirror, distroless variant";
    homepage = "https://grafana.com";
    license = lib.licenses.agpl3Only;
  };
}
