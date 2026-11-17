{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://helm.cilium.io/";
  chart = "cilium";
  version = "1.20.5";
  hash = "sha256-K3fcFNlHi1Jw5nljFv6vvnJ1rgmdLXTV1ubMmPR/Cpw=";

  meta = {
    description = "Helm chart for Cilium, eBPF-based networking, observability, and security";
    homepage = "https://cilium.io";
    license = lib.licenses.asl20;
  };
}
