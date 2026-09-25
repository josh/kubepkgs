{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/home-operations/charts/tuppr";
  chart = "tuppr";
  version = "0.5.7";
  hash = "sha256-4s2WRD04JHvTinYAS5YZBgUlmiuVcRc2Rmin2S/qBrs=";

  crds.file = ../../crds/tuppr.nix;

  meta = {
    description = "Helm chart for the Talos Linux upgrade controller";
    homepage = "https://github.com/home-operations/tuppr";
    license = lib.licenses.agpl3Only;
  };
}
