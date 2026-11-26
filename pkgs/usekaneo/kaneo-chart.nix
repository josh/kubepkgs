{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/usekaneo/charts/kaneo";
  chart = "kaneo";
  version = "2.50.0";
  hash = "sha256-6pKWQNqi2Fdvi6TEAaxpBQj4uD9ZO3KrvCEEktahOxU=";

  helmTestValues = {
    kaneo.env = {
      clientUrl = "https://kaneo.example.com";
      existingSecret = {
        enabled = true;
        name = "kaneo-auth";
      };
    };
  };

  meta = {
    description = "Helm chart for Kaneo, self-hosted project management";
    homepage = "https://kaneo.app";
    license = lib.licenses.mit;
  };
}
