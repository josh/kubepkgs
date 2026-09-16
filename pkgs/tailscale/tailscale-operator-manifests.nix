{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "tailscale-operator-manifests";
  src = kubepkgs.tailscale-operator-chart;
  chartName = "tailscale-operator";

  meta = {
    description = "Kubernetes manifests for the Tailscale Kubernetes operator";
    homepage = "https://github.com/tailscale/tailscale/tree/main/cmd/k8s-operator/deploy/chart";
    license = lib.licenses.bsd3;
  };
}
