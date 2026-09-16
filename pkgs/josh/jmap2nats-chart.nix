{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kubepkgs,
  nix-update-script,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "jmap2nats-chart";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "josh";
    repo = "jmap2nats";
    tag = "v${finalAttrs.version}";
    hash = "sha256-IsLn1A+5vH+bcBJmX96ASuQ7kE4TukgypsnqR4n7eoU=";
  };

  buildCommand = ''
    mkdir $out
    cp -R $src/charts/jmap2nats/. $out/
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=stable" ]; };

  passthru.tests = {
    files =
      runCommand "test-jmap2nats-chart-files"
        {
          __structuredAttrs = true;
        }
        ''
          diff -r ${finalAttrs.src}/charts/jmap2nats ${finalAttrs.finalPackage}
          touch $out
        '';

    render = kubepkgs.renderHelmTemplate {
      src = finalAttrs.finalPackage;
      chartName = "jmap2nats";
    };
    images = kubepkgs.checkKubeImages {
      src = finalAttrs.passthru.tests.render;
      inherit (finalAttrs) pname version;
    };
  };

  meta = {
    description = "Helm chart for the JMAP to NATS bridge";
    homepage = "https://github.com/josh/jmap2nats/tree/main/charts/jmap2nats";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
