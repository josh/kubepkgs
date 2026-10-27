{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://jellyfin.github.io/jellyfin-helm";
  chart = "jellyfin";
  version = "3.7.0";
  hash = "sha256-hyWX314xw0ftC5WMVDziCwqE8lr50jESXOU6DEGBKb0=";

  meta = {
    description = "Helm chart for Jellyfin, the free software media system";
    homepage = "https://jellyfin.org";
    license = lib.licenses.gpl2Only;
  };
}
