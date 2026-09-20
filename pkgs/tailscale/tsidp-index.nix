{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/tailscale/tsidp";
  lock = ./tsidp-index.json;

  meta = {
    description = "tsidp container image mirror";
    homepage = "https://github.com/tailscale/tsidp";
    license = lib.licenses.bsd3;
  };
}
