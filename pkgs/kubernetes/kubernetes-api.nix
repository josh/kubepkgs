{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  kubepkgs,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "kubernetes-api";
  version = "1.37.2";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "kubernetes";
    repo = "kubernetes";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Bbyu5hMQTSrvr/kDFHlRnfz5RIR7ecBfTFOGTCffn5c=";
  };

  buildCommand = ''
    mkdir -p $out/api/openapi-spec $out/api/discovery
    cp $src/api/openapi-spec/swagger.json $out/api/openapi-spec/
    cp $src/api/discovery/api__v1.json $src/api/discovery/aggregated_v2.json $out/api/discovery/
  '';

  # The regex excludes upstream's alpha, beta and rc tags
  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version-regex=^v([0-9][0-9.]*)$" ];
  };

  passthru.crds = ../../crds/kubernetes.nix;

  passthru.crdModuleGenerated = kubepkgs.buildCrdModule.fromK8s {
    name = "kubernetes";
    src = finalAttrs.finalPackage;
  };

  passthru.crdModule = {
    inherit (finalAttrs) pname version;
    name = "kubernetes";
    file = builtins.toString finalAttrs.passthru.crds;
  };

  passthru.tests.crds = kubepkgs.checkCrdModule {
    inherit (finalAttrs) pname;
    file = finalAttrs.passthru.crds;
    generated = finalAttrs.passthru.crdModuleGenerated;
  };

  meta = {
    description = "OpenAPI schema and discovery documents for the Kubernetes API";
    homepage = "https://github.com/kubernetes/kubernetes";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
})
