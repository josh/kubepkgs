{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "openclaw-browser-index";
  imageName = "ghcr.io/openclaw/openclaw";
  lock = ./openclaw-browser-index.json;

  meta = {
    description = "OpenClaw container image mirror, browser variant";
    homepage = "https://github.com/openclaw/openclaw";
    license = lib.licenses.mit;
  };
}
