{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/natsio/nats-box";
  lock = ./nats-box-index.json;

  meta = {
    description = "nats-box container image mirror";
    homepage = "https://github.com/nats-io/nats-box";
    license = lib.licenses.asl20;
  };
}
