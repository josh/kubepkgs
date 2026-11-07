{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/tailscale/tailscale";
  lock = ./tailscale-index.json;

  meta = {
    description = "Tailscale container image mirror";
    homepage = "https://tailscale.com";
    license = lib.licenses.bsd3;
  };
}
