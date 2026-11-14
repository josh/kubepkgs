{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "gitea-runner-ubuntu-2404-index";
  imageName = "docker.gitea.com/runner-images";
  lock = ./gitea-runner-ubuntu-2404-index.json;
  # Versioned tags are ubuntu-<release>[-slim|-full]-v<YY.MM.NN>; the prefix
  # fixes the Ubuntu release and variant so only the image rebuild advances.
  tagPrefix = "ubuntu-24.04-v";

  meta = {
    description = "Gitea Actions runner Ubuntu 24.04 job container image mirror";
    homepage = "https://gitea.com/gitea/runner-images";
    license = lib.licenses.mit;
  };
}
