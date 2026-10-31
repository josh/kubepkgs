{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kubepkgs,
  yq,
  nix-update-script,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "talos-manifests";
  version = "1.14.5";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "siderolabs";
    repo = "talos";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GzaPK2whp3L9eO6psXndDn7yWnA/WoDOzgTVnU+0x3s=";
  };

  buildCommand = ''
    mkdir $out
    cp $src/internal/app/machined/pkg/controllers/k8s/internal/k8stemplates/testdata/talos-service-account-crd.yaml $out/
  '';

  # The regex excludes upstream's alpha and beta tags
  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version-regex=^v([0-9][0-9.]*)$" ];
  };

  passthru.crds = ../../crds/talos.nix;

  passthru.crdModuleGenerated = kubepkgs.buildCrdModule.fromCRD {
    name = "talos";
    src = finalAttrs.finalPackage;
    crdFiles = [ "talos-service-account-crd.yaml" ];
    attrNameOverrides."serviceaccounts.talos.dev" = "talosServiceAccounts";
  };

  passthru.crdModule = {
    inherit (finalAttrs) pname version;
    name = "talos";
    file = builtins.toString finalAttrs.passthru.crds;
  };

  passthru.tests = {
    parse =
      runCommand "test-talos-manifests-parse"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ yq ];
        }
        ''
          yq -r '.kind? // empty' ${finalAttrs.finalPackage}/talos-service-account-crd.yaml >kinds.txt
          grep -qx CustomResourceDefinition kinds.txt
          touch $out
        '';
    crds = kubepkgs.checkCrdModule {
      inherit (finalAttrs) pname;
      file = finalAttrs.passthru.crds;
      generated = finalAttrs.passthru.crdModuleGenerated;
    };
  };

  meta = {
    description = "Kubernetes CRDs that Talos Linux installs into its cluster";
    homepage = "https://github.com/siderolabs/talos";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.all;
  };
})
