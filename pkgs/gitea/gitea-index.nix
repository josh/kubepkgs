{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.gitea.com/gitea";
  lock = ./gitea-index.json;

  meta = {
    description = "Gitea container image mirror";
    homepage = "https://about.gitea.com";
    license = lib.licenses.mit;
  };
}
