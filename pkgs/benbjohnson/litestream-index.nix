{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/litestream/litestream";
  lock = ./litestream-index.json;

  meta = {
    description = "Litestream container image mirror";
    homepage = "https://litestream.io";
    license = lib.licenses.asl20;
  };
}
