{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "quay.io/jetstack/cert-manager-controller";
  lock = ./cert-manager-controller-index.json;
  # Releases are vMAJOR.MINOR.PATCH, but CI build ID tags like 608111629 are
  # also published and would otherwise parse as a newer major.
  tagPattern = "v[0-9]+\\.[0-9]+\\.[0-9]+";

  meta = {
    description = "cert-manager controller container image mirror";
    homepage = "https://cert-manager.io";
    license = lib.licenses.asl20;
  };
}
