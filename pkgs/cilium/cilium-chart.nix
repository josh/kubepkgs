{ lib, kubepkgs }:
kubepkgs.fetchhelm {
  url = "https://helm.cilium.io/";
  chart = "cilium";
  version = "1.20.4";
  hash = "sha256-KYp707isjg+hw4j3Kx+2Oked6D8zwQMG6PDZmRX1FsI=";

  meta = {
    description = "Helm chart for Cilium, eBPF-based networking, observability, and security";
    homepage = "https://cilium.io";
    license = lib.licenses.asl20;
  };
}
