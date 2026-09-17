{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/home-operations/charts/tuppr";
  chart = "tuppr";
  version = "0.5.6";
  hash = "sha256-fDbemyhwvajhEjnLPC9KEn8NqRS6qm7fz2Ri+Z4wCjE=";

  meta = {
    description = "Helm chart for the Talos Linux upgrade controller";
    homepage = "https://github.com/home-operations/tuppr";
    license = lib.licenses.agpl3Only;
  };
}
