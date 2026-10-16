{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://helm.goharbor.io/";
  chart = "harbor";
  version = "1.19.4";
  hash = "sha256-Z++2NEk4GGCbU2vgjIKpCTqz5v6AOcYwj2gzwleOVQk=";

  meta = {
    description = "Helm chart for Harbor, a cloud native registry that stores, signs, and scans content";
    homepage = "https://goharbor.io";
    license = lib.licenses.asl20;
  };
}
