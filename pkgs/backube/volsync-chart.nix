{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://backube.github.io/helm-charts/";
  chart = "volsync";
  version = "0.17.0";
  hash = "sha256-mlIUJxh7EYKGpSsJFYlz9YYVaNkxTIGOU9AGFKl/0uA=";

  crds.file = ../../crds/volsync.nix;

  meta = {
    description = "Helm chart for VolSync, asynchronous volume data replication for Kubernetes";
    homepage = "https://volsync.readthedocs.io";
    license = lib.licenses.agpl3Only;
  };
}
