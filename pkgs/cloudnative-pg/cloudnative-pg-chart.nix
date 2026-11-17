{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://cloudnative-pg.github.io/charts";
  chart = "cloudnative-pg";
  version = "0.29.2";
  hash = "sha256-bAXSXQ4UWe2v8eXtUcYbc+LFv5FUpV4vd5vkLVID/Lk=";

  crds.file = ../../crds/cloudnative-pg.nix;

  meta = {
    description = "Helm chart for the CloudNativePG PostgreSQL operator";
    homepage = "https://cloudnative-pg.io";
    license = lib.licenses.asl20;
  };
}
