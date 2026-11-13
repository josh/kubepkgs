{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-metrics-mcp";
  version = "0.4.1";
  hash = "sha256-rAIkB4otK0DTj7zZ27JBVxvKK7RY8gThM3/HefGhYkk=";
  helmTestValues = {
    vm.entrypoint = "http://victoria-metrics:8428";
  };

  meta = {
    description = "Helm chart for the VictoriaMetrics MCP server, exposing MetricsQL queries to MCP clients";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
