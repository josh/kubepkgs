{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  pname = "gitea-actions-chart";
  url = "https://dl.gitea.com/charts/";
  chart = "actions";
  version = "0.1.4";
  hash = "sha256-VWI7bFXg0QEbu5Jr373EYnWLezT+83TbnLWaiP5ozOs=";
  helmTestValues = {
    enabled = true;
    giteaRootURL = "https://gitea.example.com/";
    existingSecret = "gitea-runner-token";
    existingSecretKey = "token";
  };

  meta = {
    description = "Helm chart for Gitea Actions runners";
    homepage = "https://gitea.com/gitea/helm-actions";
    license = lib.licenses.mit;
  };
}
