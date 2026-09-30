{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://victoriametrics.github.io/helm-charts";
  chart = "victoria-logs-mcp";
  version = "0.2.0";
  hash = "sha256-SGFl9TDgXP/9urFti9gRIY7HysZGM/Ul8Sz/AMFXzPU=";
  helmTestValues = {
    vl.entrypoint = "http://victoria-logs:9428";
  };

  meta = {
    description = "Helm chart for the VictoriaLogs MCP server, exposing LogsQL queries to MCP clients";
    homepage = "https://github.com/VictoriaMetrics/helm-charts";
    license = lib.licenses.asl20;
  };
}
