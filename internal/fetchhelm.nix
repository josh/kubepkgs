{
  lib,
  callPackage,
  stdenvNoCC,
  cacert,
  kubernetes,
  kubernetes-helm,
}:
args@{
  url,
  chart,
  version,
  hash,
  pname ? "${chart}-chart",
  ignoredVersions ? [ ],
  crds ? null,
  helmTestValues ? { },
  helmTestArgs ? [ ],
  meta ? { },
}:
let
  buildCrdModule = callPackage ./build-crd-module.nix { };
  update-helm-charts = callPackage ./update-helm-charts.nix { };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit pname version;

  __structuredAttrs = true;

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = hash;
  impureEnvVars = lib.fetchers.proxyImpureEnvVars;

  nativeBuildInputs = [
    cacert
    kubernetes-helm
  ];

  helmChart = chart;
  helmPullArgs =
    if (lib.strings.hasPrefix "oci://" url) then
      [
        url
        "--version"
        version
      ]
    else
      [
        chart
        "--repo"
        url
        "--version"
        version
      ];

  buildCommand = ''
    export HELM_CACHE_HOME=$TMPDIR/cache
    export HELM_CONFIG_HOME=$TMPDIR/config
    export HELM_DATA_HOME=$TMPDIR/data
    helm pull "''${helmPullArgs[@]}" --destination ./out --untar
    cp -R ./out/"$helmChart" $out
  '';

  passthru.helmChart = {
    inherit
      pname
      url
      chart
      version
      hash
      ignoredVersions
      ;
    crdFile = if crds == null then null else builtins.toString crds.file;
    inherit ((builtins.unsafeGetAttrPos "url" args)) file;
    versionLine = (builtins.unsafeGetAttrPos "version" args).line;
    hashLine = (builtins.unsafeGetAttrPos "hash" args).line;
  };

  passthru.updateScript = [
    "${lib.meta.getExe update-helm-charts}"
    "--only"
    pname
    "--write"
  ];

  passthru.crds = if crds == null then null else crds.file;

  passthru.crdModuleGenerated =
    if crds == null then
      null
    else
      buildCrdModule {
        name = chart;
        chart = finalAttrs.finalPackage;
        values = crds.values or { };
        kubeVersion = "v${kubernetes.version}";
      };

  passthru.crdModule =
    if crds == null then
      null
    else
      {
        inherit pname version;
        name = chart;
        file = builtins.toString crds.file;
      };

  passthru.tests = {
    render = callPackage ./helm-render-template.nix {
      src = finalAttrs.finalPackage;
      chartName = chart;
      helmValues = helmTestValues;
      helmArgs = helmTestArgs;
    };
    images = callPackage ./check-kube-images.nix {
      src = finalAttrs.passthru.tests.render;
      inherit pname version;
    };
  }
  // lib.attrsets.optionalAttrs (crds != null) {
    crds = callPackage ./check-crd-module.nix {
      inherit pname;
      inherit (crds) file;
      generated = finalAttrs.passthru.crdModuleGenerated;
    };
  };

  meta = {
    description = "${chart} Helm chart";
    platforms = lib.platforms.all;
  }
  // meta;

  # update-helm-charts locates the calling file via meta.position
  pos = builtins.unsafeGetAttrPos "url" args;
})
