{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "descheduler-manifests";
  src = kubepkgs.descheduler-chart;
  chartName = "descheduler";

  meta = {
    description = "Kubernetes manifests for Descheduler, which evicts pods so the Kubernetes scheduler can reschedule them onto better nodes";
    homepage = "https://github.com/kubernetes-sigs/descheduler";
    license = lib.licenses.asl20;
  };
}
