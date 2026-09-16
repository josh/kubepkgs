{ lib, kubepkgs }:
kubepkgs.renderHelmTemplate {
  pname = "jmap2nats-manifests";
  src = kubepkgs.jmap2nats-chart;
  chartName = "jmap2nats";

  meta = {
    description = "Kubernetes manifests for the JMAP to NATS bridge";
    homepage = "https://github.com/josh/jmap2nats/tree/main/charts/jmap2nats";
    license = lib.licenses.mit;
  };
}
