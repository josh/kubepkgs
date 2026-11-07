{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/rancher/local-path-provisioner";
  lock = ./local-path-provisioner-index.json;

  meta = {
    description = "Local Path Provisioner container image mirror";
    homepage = "https://github.com/rancher/local-path-provisioner";
    license = lib.licenses.asl20;
  };
}
