{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set";
  chart = "gha-runner-scale-set";
  version = "0.15.1";
  hash = "sha256-0GRr74neHHGwYe/LJ7RY8DxWopCVf3aZUaBrS0UEaEg=";
  helmTestValues = {
    controllerServiceAccount.name = "test";
    controllerServiceAccount.namespace = "default";
    githubConfigUrl = "https://github.com/test/test";
    githubConfigSecret.github_token = "test";
  };

  meta = {
    description = "Helm chart for deploying an AutoScalingRunnerSet";
    homepage = "https://github.com/actions/actions-runner-controller";
    license = lib.licenses.asl20;
  };
}
