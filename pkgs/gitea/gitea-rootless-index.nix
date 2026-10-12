{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "gitea-rootless-index";
  imageName = "docker.gitea.com/gitea";
  lock = ./gitea-rootless-index.json;

  meta = {
    description = "Gitea container image mirror, rootless variant";
    homepage = "https://about.gitea.com";
    license = lib.licenses.mit;
  };
}
