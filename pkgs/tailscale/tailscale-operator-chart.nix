{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://pkgs.tailscale.com/helmcharts";
  chart = "tailscale-operator";
  version = "1.104.4";
  hash = "sha256-CSZO4o/gO9VP3govBJDSGAK0QNUKZvGTN9g+CoQqXRU=";

  crds.file = ../../crds/tailscale-operator.nix;

  meta = {
    description = "Helm chart for the Tailscale Kubernetes operator";
    homepage = "https://github.com/tailscale/tailscale";
    license = lib.licenses.bsd3;
  };
}
