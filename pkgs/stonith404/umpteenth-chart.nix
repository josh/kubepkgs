{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/stonith404/charts/umpteenth";
  chart = "umpteenth";
  version = "0.3.0";
  hash = "sha256-KNjyzc3hv47b5wu0CaZoS4Ur86rH8mDG8bKtX24u30E=";

  helmTestValues = {
    app.url = "https://umpteenth.example.com";
  };

  meta = {
    description = "Helm chart for Umpteenth, self-hosted agent jobs that run in sandboxes and turn into scripts";
    homepage = "https://umpteenth.dev";
    license = lib.licenses.agpl3Only;
  };
}
