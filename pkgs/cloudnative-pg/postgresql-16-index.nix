{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  pname = "postgresql-16-index";
  imageName = "ghcr.io/cloudnative-pg/postgresql";
  lock = ./postgresql-16-index.json;
  # Stay on PostgreSQL 16: a new major is a data migration, not an image bump.
  tagPattern = "16\\.[0-9]+";

  meta = {
    description = "CloudNativePG PostgreSQL 16 operand container image mirror";
    homepage = "https://github.com/cloudnative-pg/postgres-containers";
    license = lib.licenses.postgresql;
  };
}
