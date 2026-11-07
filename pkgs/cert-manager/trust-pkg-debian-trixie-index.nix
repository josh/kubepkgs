{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "quay.io/jetstack/trust-pkg-debian-trixie";
  lock = ./trust-pkg-debian-trixie-index.json;

  meta = {
    description = "trust-manager Debian trixie CA bundle container image mirror";
    homepage = "https://cert-manager.io/docs/trust/trust-manager/";
    license = lib.licenses.mpl20;
  };
}
