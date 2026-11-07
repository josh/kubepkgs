{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/natsio/nats-server-config-reloader";
  lock = ./nats-server-config-reloader-index.json;

  meta = {
    description = "NATS server config reloader container image mirror";
    homepage = "https://github.com/nats-io/nack";
    license = lib.licenses.asl20;
  };
}
