{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "nack-manifests";
  src = kubepkgs.nack-chart;
  chartName = "nack";

  meta = {
    description = "Kubernetes manifests for NACK, the NATS controller for Kubernetes";
    homepage = "https://github.com/nats-io/k8s/tree/main/helm/charts/nack";
    license = lib.licenses.asl20;
  };
}
