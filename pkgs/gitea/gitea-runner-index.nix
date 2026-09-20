{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "gitea-runner-index";
  imageName = "docker.gitea.com/runner";
  lock = ./gitea-runner-index.json;

  meta = {
    description = "Gitea Actions runner container image mirror";
    homepage = "https://gitea.com/gitea/act_runner";
    license = lib.licenses.mit;
  };
}
