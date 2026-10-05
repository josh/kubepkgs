{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://kubernetes-sigs.github.io/descheduler/";
  chart = "descheduler";
  version = "0.37.0";
  hash = "sha256-jQW7Ed8gvSSYVgVrVHG++LgVK6a6guaDefr40NDxJA8=";

  meta = {
    description = "Helm chart for Descheduler, which evicts pods so the Kubernetes scheduler can reschedule them onto better nodes";
    homepage = "https://github.com/kubernetes-sigs/descheduler";
    license = lib.licenses.asl20;
  };
}
