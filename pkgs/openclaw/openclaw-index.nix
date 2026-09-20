{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/openclaw/openclaw";
  lock = ./openclaw-index.json;

  meta = {
    description = "OpenClaw container image mirror";
    homepage = "https://github.com/openclaw/openclaw";
    license = lib.licenses.mit;
  };
}
