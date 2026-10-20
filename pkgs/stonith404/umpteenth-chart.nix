{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/stonith404/charts/umpteenth";
  chart = "umpteenth";
  version = "0.4.0";
  hash = "sha256-9ZxHbe40+4SLIBcTFUtK1YPbA+RVJG1sl2HxquPIV7Q=";

  helmTestValues = {
    app.url = "https://umpteenth.example.com";
  };

  meta = {
    description = "Helm chart for Umpteenth, self-hosted agent jobs that run in sandboxes and turn into scripts";
    homepage = "https://umpteenth.dev";
    license = lib.licenses.agpl3Only;
  };
}
