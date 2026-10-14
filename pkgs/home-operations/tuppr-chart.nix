{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/home-operations/charts/tuppr";
  chart = "tuppr";
  version = "0.5.8";
  hash = "sha256-JgDOTqhhRowuqSO+7EPO1jBLdI/XMmqIBa+ZieBfIL8=";

  crds.file = ../../crds/tuppr.nix;

  meta = {
    description = "Helm chart for the Talos Linux upgrade controller";
    homepage = "https://github.com/home-operations/tuppr";
    license = lib.licenses.agpl3Only;
  };
}
