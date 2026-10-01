{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set";
  chart = "gha-runner-scale-set";
  version = "0.15.0";
  hash = "sha256-ooeRpectFlfQjT//iVNAHc7wEIju+fTcANt8YH5qV/w=";
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
