{
  lib,
  callPackage,
  stdenvNoCC,
  cacert,
  kubernetes-helm,
}:
args@{
  url,
  chart,
  version,
  hash,
  pname ? "${chart}-chart",
  helmTestValues ? { },
  helmTestArgs ? [ ],
  meta ? { },
}:
let
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
      ;
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
  };

  meta = {
    description = "${chart} Helm chart";
    platforms = lib.platforms.all;
  }
  // meta;

  # update-helm-charts locates the calling file via meta.position
  pos = builtins.unsafeGetAttrPos "url" args;
})
