{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "vminsert-cluster-index";
  imageName = "docker.io/victoriametrics/vminsert";
  lock = ./vminsert-cluster-index.json;

  meta = {
    description = "vminsert container image mirror, cluster variant";
    homepage = "https://victoriametrics.com";
    license = lib.licenses.asl20;
  };
}
