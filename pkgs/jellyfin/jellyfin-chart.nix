{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://jellyfin.github.io/jellyfin-helm";
  chart = "jellyfin";
  version = "3.6.0";
  hash = "sha256-Hr4xvXQyaegZl9OIRBfsI2qvHQFvqU7PcRFmzpk8r0Y=";

  meta = {
    description = "Helm chart for Jellyfin, the free software media system";
    homepage = "https://jellyfin.org";
    license = lib.licenses.gpl2Only;
  };
}
