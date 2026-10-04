{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/josh/ceph-mgr-endpoint-controller";
  lock = ./ceph-mgr-endpoint-controller-index.json;

  meta = {
    description = "ceph-mgr-endpoint-controller container image mirror";
    homepage = "https://github.com/josh/ceph-mgr-endpoint-controller";
    license = lib.licenses.mit;
  };
}
