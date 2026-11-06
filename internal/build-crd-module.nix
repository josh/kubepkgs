{
  lib,
  path,
  kubernetes-helm,
  nix,
  nixfmt,
  python3,
  runCommand,
}:
let
  generate =
    name: expr:
    runCommand "k8s-${name}-gen.nix"
      {
        nativeBuildInputs = [
          nix
          nixfmt
        ];
      }
      ''
        export HOME=$TMPDIR NIX_STATE_DIR=$TMPDIR/state NIX_LOG_DIR=$TMPDIR/log NIX_CONF_DIR=$TMPDIR
        nix --extra-experimental-features nix-command eval --store dummy:// --impure --raw --expr ${lib.escapeShellArg "let lib = import ${path}/lib; in ${expr}"} > raw.nix
        nixfmt raw.nix
        cp raw.nix $out
      '';

  fromCRD =
    {
      name,
      crdFiles,
      attrNameOverrides ? { },
    }:
    generate name "import ${./crd-generator/generator.nix} { inherit lib; schema = lib.importJSON ${
      runCommand "${name}-jsonschema.json" { } ''
        ${python3.withPackages (ps: [ ps.pyyaml ])}/bin/python ${./crd-generator/crd2jsonschema.py} \
          ${lib.escapeShellArg (builtins.toJSON attrNameOverrides)} ${lib.concatStringsSep " " crdFiles} > $out
      ''
    }; }";
in
{
  inherit fromCRD;

  fromK8s =
    { name, src }:
    generate name "import ${./crd-generator/generator.nix} ({ inherit lib; } // import ${./crd-generator/sources/k8s.nix} { inherit lib; } \"${src}\")";

  fromChartCRD =
    {
      name,
      chart,
      values,
      kubeVersion,
    }:
    fromCRD {
      inherit name;
      crdFiles = [
        (runCommand "chart-crds-${name}.yaml"
          {
            values = builtins.toJSON values;
            passAsFile = [ "values" ];
          }
          ''
            HELM_CACHE_HOME="$TMP" ${kubernetes-helm}/bin/helm template --include-crds \
              --kube-version ${kubeVersion} --values "$valuesPath" ${name} ${chart} > $out
          ''
        )
      ];
    };
}
