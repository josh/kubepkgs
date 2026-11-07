{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "registry.k8s.io/sig-storage/csi-attacher";
  lock = ./csi-attacher-index.json;

  meta = {
    description = "CSI external-attacher container image mirror";
    homepage = "https://github.com/kubernetes-csi/external-attacher";
    license = lib.licenses.asl20;
  };
}
