{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/healthchecks/healthchecks";
  lock = ./healthchecks-index.json;

  meta = {
    description = "Healthchecks container image mirror";
    homepage = "https://healthchecks.io";
    license = lib.licenses.bsd3;
  };
}
