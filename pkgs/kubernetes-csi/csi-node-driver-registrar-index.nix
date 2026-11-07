{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "registry.k8s.io/sig-storage/csi-node-driver-registrar";
  lock = ./csi-node-driver-registrar-index.json;

  meta = {
    description = "CSI node-driver-registrar container image mirror";
    homepage = "https://github.com/kubernetes-csi/node-driver-registrar";
    license = lib.licenses.asl20;
  };
}
