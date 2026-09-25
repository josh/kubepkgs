{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://movetokube.github.io/postgres-operator";
  chart = "ext-postgres-operator";
  version = "3.0.0";
  hash = "sha256-sf4MgShIK+I5fNoCO1aMqFw+T9SW5hY7qS3awQo8XU0=";

  crds.file = ../../crds/ext-postgres-operator.nix;

  meta = {
    description = "Helm chart for the external PostgreSQL operator";
    homepage = "https://github.com/movetokube/postgres-operator";
    license = lib.licenses.mit;
  };
}
