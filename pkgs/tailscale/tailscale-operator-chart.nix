{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://pkgs.tailscale.com/helmcharts";
  chart = "tailscale-operator";
  version = "1.102.4";
  hash = "sha256-dMU3iun/5Vl8TJwT5zqu1hwlUR3HolZ2KYPi7JtkTuI=";

  meta = {
    description = "Helm chart for the Tailscale Kubernetes operator";
    homepage = "https://github.com/tailscale/tailscale";
    license = lib.licenses.bsd3;
  };
}
