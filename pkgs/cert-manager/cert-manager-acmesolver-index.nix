{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "quay.io/jetstack/cert-manager-acmesolver";
  lock = ./cert-manager-acmesolver-index.json;
  # Releases are vMAJOR.MINOR.PATCH, but CI build ID tags like 608111629 are
  # also published and would otherwise parse as a newer major.
  tagPattern = "v[0-9]+\\.[0-9]+\\.[0-9]+";

  meta = {
    description = "cert-manager ACME HTTP-01 solver container image mirror";
    homepage = "https://cert-manager.io";
    license = lib.licenses.asl20;
  };
}
