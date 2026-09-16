{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "cilium-manifests";
  src = kubepkgs.cilium-chart;
  chartName = "cilium";

  meta = {
    description = "Kubernetes manifests for Cilium, eBPF-based networking, observability, and security";
    homepage = "https://github.com/cilium/cilium";
    license = lib.licenses.asl20;
  };
}
