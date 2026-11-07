{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "registry.k8s.io/sig-storage/snapshot-controller";
  lock = ./snapshot-controller-index.json;

  meta = {
    description = "CSI snapshot controller container image mirror";
    homepage = "https://github.com/kubernetes-csi/external-snapshotter";
    license = lib.licenses.asl20;
  };
}
