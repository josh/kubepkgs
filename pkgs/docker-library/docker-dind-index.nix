{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "docker-dind-index";
  imageName = "docker.io/library/docker";
  lock = ./docker-dind-index.json;

  meta = {
    description = "Docker-in-Docker container image mirror";
    homepage = "https://hub.docker.com/_/docker";
    license = lib.licenses.asl20;
  };
}
