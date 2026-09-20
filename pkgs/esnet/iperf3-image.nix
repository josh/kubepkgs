{ kubepkgs, iperf3 }:
kubepkgs.buildOciImage {
  name = "iperf3";
  contents = [ iperf3 ];
  config = {
    User = "65534:65534";
    Entrypoint = [ "${iperf3}/bin/iperf3" ];
    ExposedPorts = {
      "5201/tcp" = { };
      "5201/udp" = { };
    };
  };

  meta = {
    description = "iperf3 network throughput server image";
    homepage = "https://github.com/esnet/iperf";
  };
}
