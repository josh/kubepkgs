{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "mqtt2nats-manifests";
  src = kubepkgs.mqtt2nats-chart;
  chartName = "mqtt2nats";

  meta = {
    description = "Kubernetes manifests for the MQTT to NATS bridge";
    homepage = "https://github.com/josh/mqtt2nats/tree/main/charts/mqtt2nats";
    license = lib.licenses.mit;
  };
}
