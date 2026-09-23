{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://cloudnative-pg.github.io/charts";
  chart = "cloudnative-pg";
  version = "0.29.1";
  hash = "sha256-VWDikb5gw9s35yZYk3BqcojQtEE/b3gdDN6TCcJXzZ4=";

  meta = {
    description = "Helm chart for the CloudNativePG PostgreSQL operator";
    homepage = "https://cloudnative-pg.io";
    license = lib.licenses.asl20;
  };
}
