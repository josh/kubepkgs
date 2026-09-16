{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "nats-manifests";
  src = kubepkgs.nats-chart;
  chartName = "nats";

  meta = {
    description = "Kubernetes manifests for NATS, a cloud native messaging system";
    homepage = "https://github.com/nats-io/k8s/tree/main/helm/charts/nats";
    license = lib.licenses.asl20;
  };
}
