{ lib, kubepkgs }:
kubepkgs.fetchOciImage {
  imageName = "ghcr.io/victoriametrics/mcp-victoriametrics";
  lock = ./mcp-victoriametrics-index.json;
  # Each release is tagged both with and without the v prefix; follow one.
  tagPattern = "v[0-9]+\\.[0-9]+\\.[0-9]+";

  meta = {
    description = "VictoriaMetrics MCP server container image mirror";
    homepage = "https://github.com/VictoriaMetrics/mcp-victoriametrics";
    license = lib.licenses.asl20;
  };
}
