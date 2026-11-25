{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://grafana-community.github.io/helm-charts";
  chart = "grafana";
  version = "14.6.0";
  hash = "sha256-VMSN+XdiEsmTSjE80tLhKE5wxe5I/UEIbGESV86xHJg=";

  meta = {
    description = "Helm chart for Grafana, a tool for querying and visualizing time series and metrics";
    homepage = "https://grafana.com";
    license = lib.licenses.asl20;
  };
}
