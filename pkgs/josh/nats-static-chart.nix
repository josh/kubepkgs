{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kubepkgs,
  nix-update-script,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nats-static-chart";
  version = "0.0.6";

  src = fetchFromGitHub {
    owner = "josh";
    repo = "nats-static";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Zga7q6EHIksbqcjyWroxKNjJBdIdufxggNP8Rk1Myto=";
  };

  buildCommand = ''
    mkdir $out
    cp -R $src/charts/nats-static/. $out/
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=stable" ]; };

  passthru.tests = {
    files =
      runCommand "test-nats-static-chart-files"
        {
          __structuredAttrs = true;
        }
        ''
          diff -r ${finalAttrs.src}/charts/nats-static ${finalAttrs.finalPackage}
          touch $out
        '';

    render = kubepkgs.renderHelmTemplate {
      src = finalAttrs.finalPackage;
      chartName = "nats-static";
    };
    images = kubepkgs.checkKubeImages {
      src = finalAttrs.passthru.tests.render;
      inherit (finalAttrs) pname version;
    };
  };

  meta = {
    description = "Helm chart for the nats-static file server";
    homepage = "https://github.com/josh/nats-static/tree/main/charts/nats-static";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
