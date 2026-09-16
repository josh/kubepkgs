{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kubepkgs,
  nix-update-script,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "restic-rados-server-chart";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "josh";
    repo = "restic-rados-server";
    tag = "v${finalAttrs.version}";
    hash = "sha256-SZiFHnG+ZkA49Raz1OijaUFSjb9hjKtIFuvg5uqC2T0=";
  };

  buildCommand = ''
    mkdir $out
    cp -R $src/charts/restic-rados-server/. $out/
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=stable" ]; };

  passthru.tests = {
    files =
      runCommand "test-restic-rados-server-chart-files"
        {
          __structuredAttrs = true;
        }
        ''
          diff -r ${finalAttrs.src}/charts/restic-rados-server ${finalAttrs.finalPackage}
          touch $out
        '';

    render = kubepkgs.renderHelmTemplate {
      src = finalAttrs.finalPackage;
      chartName = "restic-rados-server";
    };
    images = kubepkgs.checkKubeImages {
      src = finalAttrs.passthru.tests.render;
      inherit (finalAttrs) pname version;
    };
  };

  meta = {
    description = "Helm chart for the restic REST server backed by RADOS";
    homepage = "https://github.com/josh/restic-rados-server/tree/main/charts/restic-rados-server";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
