{
  testers,
}:
{
  image,
  testScript,
}:
testers.runNixOSTest {
  name = "test-${image.imageName}-image";

  nodes.machine = {
    virtualisation.podman.enable = true;
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("podman load < ${image}")
    image = "${image.imageName}:${image.imageTag}"
  ''
  + testScript;
}
