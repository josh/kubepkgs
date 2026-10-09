{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/stonith404/charts/umpteenth";
  chart = "umpteenth";
  version = "0.2.0";
  hash = "sha256-8uVARwwlUiJleNG+SY3o7M9coi2h7qUBQda+I6Vsii4=";

  helmTestValues = {
    app.url = "https://umpteenth.example.com";
  };

  meta = {
    description = "Helm chart for Umpteenth, self-hosted agent jobs that run in sandboxes and turn into scripts";
    homepage = "https://umpteenth.dev";
    license = lib.licenses.agpl3Only;
  };
}
