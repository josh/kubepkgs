{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://kubernetes-sigs.github.io/descheduler/";
  chart = "descheduler";
  version = "0.36.0";
  hash = "sha256-j7JvnwNF3kihRTzi9Q22cMr8bsEDGTm6Hp6qDGWn4zY=";

  meta = {
    description = "Helm chart for Descheduler, which evicts pods so the Kubernetes scheduler can reschedule them onto better nodes";
    homepage = "https://github.com/kubernetes-sigs/descheduler";
    license = lib.licenses.asl20;
  };
}
