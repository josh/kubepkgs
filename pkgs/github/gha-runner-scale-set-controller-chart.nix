{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller";
  chart = "gha-runner-scale-set-controller";
  version = "0.15.1";
  hash = "sha256-oTtBDvxVcnWXGFbKvVJ3cf5djYYYK7zPjUDOq8xRNOc=";

  crds.file = ../../crds/gha-runner-scale-set-controller.nix;

  meta = {
    description = "Helm chart for installing the actions-runner-controller CRDs";
    homepage = "https://github.com/actions/actions-runner-controller";
    license = lib.licenses.asl20;
  };
}
