{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nur,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "prometheus-restic-exporter-chart";
  version = "2.0.4";

  src = fetchFromGitHub {
    owner = "josh";
    repo = "restic-exporter";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GZxCawHupl/bbOCrMXZgVjH4fpwfAm5aOaKp0Vy/Q44=";
  };

  buildCommand = ''
    mkdir $out
    cp -R $src/charts/restic-exporter/. $out/
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=stable" ]; };

  passthru.tests = {
    render = nur.repos.josh.renderHelmTemplate {
      src = finalAttrs.finalPackage;
      chartName = "restic-exporter";
      helmValues = {
        restic.repository = "s3:https://s3.example.com/restic";
      };
    };
    images = nur.repos.josh.checkKubeImages {
      src = finalAttrs.passthru.tests.render;
      inherit (finalAttrs) pname version;
    };
  };

  meta = {
    description = "Helm chart for the Prometheus Restic exporter";
    homepage = "https://github.com/josh/restic-exporter/tree/main/charts/restic-exporter";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
