{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://jellyfin.github.io/jellyfin-helm";
  chart = "jellyfin";
  version = "3.4.0";
  hash = "sha256-HHI84acig0kLhjA+7AkNsXGo5Ks0+xDGtywfgTSecdQ=";

  meta = {
    description = "Helm chart for Jellyfin, the free software media system";
    homepage = "https://jellyfin.org";
    license = lib.licenses.gpl2Only;
  };
}
