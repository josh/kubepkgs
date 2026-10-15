{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://helm.cilium.io/";
  chart = "cilium";
  version = "1.20.3";
  hash = "sha256-Z2McaGxaJnEw+jyI/bljUOj7f5Cg3XDbiFkVqcCWzkQ=";

  meta = {
    description = "Helm chart for Cilium, eBPF-based networking, observability, and security";
    homepage = "https://cilium.io";
    license = lib.licenses.asl20;
  };
}
