{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "nats-static-manifests";
  src = kubepkgs.nats-static-chart;
  chartName = "nats-static";

  meta = {
    description = "Kubernetes manifests for the nats-static file server";
    homepage = "https://github.com/josh/nats-static/tree/main/charts/nats-static";
    license = lib.licenses.mit;
  };
}
