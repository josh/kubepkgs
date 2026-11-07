{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "docker.io/natsio/jetstream-controller";
  lock = ./jetstream-controller-index.json;

  meta = {
    description = "NATS JetStream controller container image mirror";
    homepage = "https://github.com/nats-io/nack";
    license = lib.licenses.asl20;
  };
}
