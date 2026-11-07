{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "registry.k8s.io/sig-storage/csi-provisioner";
  lock = ./csi-provisioner-index.json;

  meta = {
    description = "CSI external-provisioner container image mirror";
    homepage = "https://github.com/kubernetes-csi/external-provisioner";
    license = lib.licenses.asl20;
  };
}
