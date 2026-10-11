{
  lib,
  skopeo,
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
    image = "localhost/${image.imageName}:${image.imageTag}"
    machine.succeed(f"${lib.meta.getExe skopeo} copy --insecure-policy oci:${image}:${image.imageTag} containers-storage:{image}")
  ''
  + testScript;
}
