{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/victoriametrics/mcp-victorialogs";
  lock = ./mcp-victorialogs-index.json;
  # Each release is tagged both with and without the v prefix; follow one.
  tagPattern = "v[0-9]+\\.[0-9]+\\.[0-9]+";

  meta = {
    description = "VictoriaLogs MCP server container image mirror";
    homepage = "https://github.com/VictoriaMetrics/mcp-victorialogs";
    license = lib.licenses.asl20;
  };
}
