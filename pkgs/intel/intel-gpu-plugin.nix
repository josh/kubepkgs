{
  lib,
  buildGo127Module,
  fetchFromGitHub,
  nix-update-script,
  runCommand,
}:
# Remove go 1.27 workaround once nixpkgs defaults to go 1.27 or newer.
buildGo127Module (finalAttrs: {
  pname = "intel-gpu-plugin";
  version = "0.37.1";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "intel-device-plugins-for-kubernetes";
    tag = "v${finalAttrs.version}";
    hash = "sha256-6aN/d3USW1Uh9dEihlfgC7XnWHMsluQLwEIWEiCKrw8=";
  };

  vendorHash = "sha256-hri9NyBAW8ymDPVqhNNnFn9ynbI7gO88u0Gz0PLBwek=";

  subPackages = [ "cmd/gpu_plugin" ];

  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];

  passthru.updateScript = nix-update-script { };

  passthru.tests = {
    help =
      runCommand "test-intel-gpu-plugin-help" { nativeBuildInputs = [ finalAttrs.finalPackage ]; }
        ''
          gpu_plugin -h 2>output.txt || true
          grep --quiet -- "-shared-dev-num" output.txt
          grep --quiet -- "-allocation-policy" output.txt
          touch $out
        '';
  };

  meta = {
    description = "Kubernetes device plugin advertising Intel GPUs as gpu.intel.com/i915 resources";
    homepage = "https://github.com/intel/intel-device-plugins-for-kubernetes";
    license = lib.licenses.asl20;
    mainProgram = "gpu_plugin";
    platforms = lib.platforms.linux;
  };
})
