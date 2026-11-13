{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://pkgs.tailscale.com/helmcharts";
  chart = "tailscale-operator";
  version = "1.104.7";
  hash = "sha256-kbEurwRbmkn0PKaHGdFmG/LZNUHK0bmwuO2NpnBCdY4=";

  crds.file = ../../crds/tailscale-operator.nix;

  meta = {
    description = "Helm chart for the Tailscale Kubernetes operator";
    homepage = "https://github.com/tailscale/tailscale";
    license = lib.licenses.bsd3;
  };
}
