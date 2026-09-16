{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kubepkgs,
  nix-update-script,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mqtt2nats-chart";
  version = "0.0.5";

  src = fetchFromGitHub {
    owner = "josh";
    repo = "mqtt2nats";
    tag = "v${finalAttrs.version}";
    hash = "sha256-updnebDXrmgl3iy4il87EIZRgujySonLUv0ORWyr7Ro=";
  };

  buildCommand = ''
    mkdir $out
    cp -R $src/charts/mqtt2nats/. $out/
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=stable" ]; };

  passthru.tests = {
    files =
      runCommand "test-mqtt2nats-chart-files"
        {
          __structuredAttrs = true;
        }
        ''
          diff -r ${finalAttrs.src}/charts/mqtt2nats ${finalAttrs.finalPackage}
          touch $out
        '';

    render = kubepkgs.renderHelmTemplate {
      src = finalAttrs.finalPackage;
      chartName = "mqtt2nats";
    };
    images = kubepkgs.checkKubeImages {
      src = finalAttrs.passthru.tests.render;
      inherit (finalAttrs) pname version;
    };
  };

  meta = {
    description = "Helm chart for the MQTT to NATS bridge";
    homepage = "https://github.com/josh/mqtt2nats/tree/main/charts/mqtt2nats";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
