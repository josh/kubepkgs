{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  pname = "cloudnative-pg-cluster-chart";
  url = "https://cloudnative-pg.github.io/charts";
  chart = "cluster";
  version = "0.9.0";
  hash = "sha256-AepQtPPli8wf67Y2xHfR4s9F5DwFS1/ymTgmOlXHoqk=";

  meta = {
    description = "Deploys and manages a CloudNativePG cluster and its associated resources";
    homepage = "https://cloudnative-pg.io";
    license = lib.licenses.asl20;
  };
}
