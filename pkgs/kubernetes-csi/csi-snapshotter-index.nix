{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "registry.k8s.io/sig-storage/csi-snapshotter";
  lock = ./csi-snapshotter-index.json;

  meta = {
    description = "CSI external-snapshotter sidecar container image mirror";
    homepage = "https://github.com/kubernetes-csi/external-snapshotter";
    license = lib.licenses.asl20;
  };
}
