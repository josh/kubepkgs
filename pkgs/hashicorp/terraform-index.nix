{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/hashicorp/terraform";
  lock = ./terraform-index.json;

  meta = {
    description = "Terraform container image mirror";
    homepage = "https://www.terraform.io/";
    license = lib.licenses.bsl11;
  };
}
