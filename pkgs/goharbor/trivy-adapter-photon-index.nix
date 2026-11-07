{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/goharbor/trivy-adapter-photon";
  lock = ./trivy-adapter-photon-index.json;

  meta = {
    description = "Harbor Trivy adapter container image mirror";
    homepage = "https://goharbor.io";
    license = lib.licenses.asl20;
  };
}
