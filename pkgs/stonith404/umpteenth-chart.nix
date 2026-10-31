{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/stonith404/charts/umpteenth";
  chart = "umpteenth";
  version = "0.5.0";
  hash = "sha256-1xY8qc2fWLVfxSQbPoLPu5pzIg/CuerjMjr9BXdYWJA=";

  helmTestValues = {
    app.url = "https://umpteenth.example.com";
  };

  meta = {
    description = "Helm chart for Umpteenth, self-hosted agent jobs that run in sandboxes and turn into scripts";
    homepage = "https://umpteenth.dev";
    license = lib.licenses.agpl3Only;
  };
}
