{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "registry.k8s.io/sig-storage/csi-resizer";
  lock = ./csi-resizer-index.json;

  meta = {
    description = "CSI external-resizer container image mirror";
    homepage = "https://github.com/kubernetes-csi/external-resizer";
    license = lib.licenses.asl20;
  };
}
