{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kubepkgs,
  nix-update-script,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kube-ups-taint-chart";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "josh";
    repo = "kube-ups-taint";
    tag = "v${finalAttrs.version}";
    hash = "sha256-LCaDRoPe2BtQtCPxrc5f9I1bkgSrbRZOKVKXnpYsD0s=";
  };

  buildCommand = ''
    mkdir $out
    cp -R $src/charts/kube-ups-taint/. $out/
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=stable" ]; };

  passthru.tests = {
    files =
      runCommand "test-kube-ups-taint-chart-files"
        {
          __structuredAttrs = true;
        }
        ''
          diff -r ${finalAttrs.src}/charts/kube-ups-taint ${finalAttrs.finalPackage}
          touch $out
        '';

    render = kubepkgs.renderHelmTemplate {
      src = finalAttrs.finalPackage;
      chartName = "kube-ups-taint";
    };
    images = kubepkgs.checkKubeImages {
      src = finalAttrs.passthru.tests.render;
      inherit (finalAttrs) pname version;
    };
  };

  meta = {
    description = "Helm chart for the UPS node taint controller";
    homepage = "https://github.com/josh/kube-ups-taint/tree/main/charts/kube-ups-taint";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
