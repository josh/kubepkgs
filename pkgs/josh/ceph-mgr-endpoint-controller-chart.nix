{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kubepkgs,
  nix-update-script,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ceph-mgr-endpoint-controller-chart";
  version = "0.7.4";

  src = fetchFromGitHub {
    owner = "josh";
    repo = "ceph-mgr-endpoint-controller";
    tag = "v${finalAttrs.version}";
    hash = "sha256-yDppUBHU1THw6JvjBqN74Y1ub6IXLoMi8TvLhlCh4Fg=";
  };

  buildCommand = ''
    mkdir $out
    cp -R $src/charts/ceph-mgr-endpoint-controller/. $out/
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=stable" ]; };

  passthru.tests = {
    files =
      runCommand "test-ceph-mgr-endpoint-controller-chart-files"
        {
          __structuredAttrs = true;
        }
        ''
          diff -r ${finalAttrs.src}/charts/ceph-mgr-endpoint-controller ${finalAttrs.finalPackage}
          touch $out
        '';

    render = kubepkgs.renderHelmTemplate {
      src = finalAttrs.finalPackage;
      chartName = "ceph-mgr-endpoint-controller";
    };
    images = kubepkgs.checkKubeImages {
      src = finalAttrs.passthru.tests.render;
      inherit (finalAttrs) pname version;
    };
  };

  meta = {
    description = "Helm chart for the Ceph manager endpoint controller";
    homepage = "https://github.com/josh/ceph-mgr-endpoint-controller/tree/main/charts/ceph-mgr-endpoint-controller";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
