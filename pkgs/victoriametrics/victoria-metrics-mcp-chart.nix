{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-mcp";
  version = "0.5.0";
  hash = "sha256-0pDu37w7RoZGAIlkNAmBu+AvPj7YoSbHLoWL7qgVPx0=";
  helmTestValues = {
    vm.entrypoint = "http://victoria-metrics:8428";
  };

  meta = {
    description = "Helm chart for the VictoriaMetrics MCP server, exposing MetricsQL queries to MCP clients";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
