{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "cert-manager-manifests";
  src = kubepkgs.cert-manager-chart;
  chartName = "cert-manager";

  meta = {
    description = "Kubernetes manifests for cert-manager, automating TLS certificate management on Kubernetes";
    homepage = "https://cert-manager.io";
    license = lib.licenses.asl20;
  };
}
