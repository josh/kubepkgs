{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "vmstorage-cluster-index";
  imageName = "docker.io/victoriametrics/vmstorage";
  lock = ./vmstorage-cluster-index.json;

  meta = {
    description = "vmstorage container image mirror, cluster variant";
    homepage = "https://victoriametrics.com";
    license = lib.licenses.asl20;
  };
}
