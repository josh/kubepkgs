{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://pkgs.tailscale.com/helmcharts";
  chart = "tailscale-operator";
  version = "1.104.1";
  hash = "sha256-/GFsFzT/OlSwvJPH+WCuhp49Q70usnjJbrOYo7cSqQ8=";

  crds.file = ../../crds/tailscale-operator.nix;

  meta = {
    description = "Helm chart for the Tailscale Kubernetes operator";
    homepage = "https://github.com/tailscale/tailscale";
    license = lib.licenses.bsd3;
  };
}
