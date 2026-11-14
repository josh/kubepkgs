{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "gitea-runner-images-index";
  imageName = "docker.gitea.com/runner-images";
  lock = ./gitea-runner-images-index.json;
  # Versioned tags are ubuntu-<release>[-slim|-full]-v<YY.MM.NN>; the prefix
  # fixes the Ubuntu release and variant so only the image rebuild advances.
  tagPrefix = "ubuntu-24.04-v";

  meta = {
    description = "Gitea Actions runner job container image mirror";
    homepage = "https://gitea.com/gitea/runner-images";
    license = lib.licenses.mit;
  };
}
