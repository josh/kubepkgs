{ kubepkgs, iperf3 }:
kubepkgs.buildOciImage {
  name = "iperf3";
  contents = [ iperf3 ];
  extraCommands = "mkdir -m 1777 tmp";
  config = {
    User = "65534:65534";
    Entrypoint = [ "${iperf3}/bin/iperf3" ];
    ExposedPorts = {
      "5201/tcp" = { };
      "5201/udp" = { };
    };
  };

  testScript = ''
    machine.succeed(f"podman run -d --name server --network host {image} --server")
    machine.wait_for_open_port(5201)
    output = machine.succeed(f"podman run --rm --network host {image} --client 127.0.0.1 --time 1")
    assert "iperf Done." in output, output
  '';

  meta = {
    description = "iperf3 network throughput server image";
    homepage = "https://github.com/esnet/iperf";
  };
}
