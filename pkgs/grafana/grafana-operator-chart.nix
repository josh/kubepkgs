{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/grafana/helm-charts/grafana-operator";
  chart = "grafana-operator";
  version = "5.26.0";
  hash = "sha256-NeEsuZE5RiwWmBQpDHR9SINz4bTK1q7m/MgIqZTzrMU=";

  crds.file = ../../crds/grafana-operator.nix;

  meta = {
    description = "Helm chart for the Grafana operator, managing Grafana instances on Kubernetes";
    homepage = "https://github.com/grafana/grafana-operator";
    license = lib.licenses.asl20;
  };
}
