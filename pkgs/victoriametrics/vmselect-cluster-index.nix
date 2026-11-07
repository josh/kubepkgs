{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "vmselect-cluster-index";
  imageName = "docker.io/victoriametrics/vmselect";
  lock = ./vmselect-cluster-index.json;

  meta = {
    description = "vmselect container image mirror, cluster variant";
    homepage = "https://victoriametrics.com";
    license = lib.licenses.asl20;
  };
}
