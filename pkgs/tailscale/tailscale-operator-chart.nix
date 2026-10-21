{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://pkgs.tailscale.com/helmcharts";
  chart = "tailscale-operator";
  version = "1.104.2";
  hash = "sha256-kAIed9FWIGh76Aof6pa1KUDxcXYQWyby6EPSkTCuxsk=";

  crds.file = ../../crds/tailscale-operator.nix;

  meta = {
    description = "Helm chart for the Tailscale Kubernetes operator";
    homepage = "https://github.com/tailscale/tailscale";
    license = lib.licenses.bsd3;
  };
}
