{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kubepkgs,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "prometheus-restic-exporter-chart";
  version = "2.0.5";

  src = fetchFromGitHub {
    owner = "josh";
    repo = "restic-exporter";
    tag = "v${finalAttrs.version}";
    hash = "sha256-PAKfdfGiD9tFOl/P33pPsKylnDOJWCSqmamVZrBsNes=";
  };

  buildCommand = ''
    mkdir $out
    cp -R $src/charts/restic-exporter/. $out/
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=stable" ]; };

  passthru.tests = {
    render = kubepkgs.renderHelmTemplate {
      src = finalAttrs.finalPackage;
      chartName = "restic-exporter";
      helmValues = {
        restic.repository = "s3:https://s3.example.com/restic";
      };
    };
    images = kubepkgs.checkKubeImages {
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
