{
  lib,
  kubernetes-helm,
  nixfmt,
  python3,
  runCommand,
}:
let
  fromCRD =
    {
      name,
      crdFiles,
      attrNameOverrides ? { },
    }:
    import ./crd-generator/generator.nix {
      inherit
        lib
        name
        nixfmt
        runCommand
        ;
      schema = lib.importJSON (
        runCommand "${name}-jsonschema.json" { } ''
          ${python3.withPackages (ps: [ ps.pyyaml ])}/bin/python ${./crd-generator/crd2jsonschema.py} \
            ${lib.escapeShellArg (builtins.toJSON attrNameOverrides)} ${lib.concatStringsSep " " crdFiles} > $out
        ''
      );
    };
in
{
  inherit fromCRD;

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
