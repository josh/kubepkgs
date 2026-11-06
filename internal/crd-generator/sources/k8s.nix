{ lib }:
let
  genNamespaced =
    core: aggregated:
    let
      core' =
        let
          data = builtins.fromJSON (builtins.readFile core);
        in
        {
          core = {
            ${data.groupVersion} = lib.mergeAttrsList (
              lib.concatMap (
                res:
                lib.optional (res.singularName != "") {
                  ${res.kind} = res.namespaced;
                }
              ) data.resources
            );
          };
        };

      aggregated' =
        let
          data = builtins.fromJSON (builtins.readFile aggregated);
        in
        lib.mergeAttrsList (
          map (item: {
            ${item.metadata.name} = lib.mergeAttrsList (
              map (version: {
                ${version.version} = lib.mergeAttrsList (
                  map (res: {
                    ${res.responseKind.kind} = res.scope == "Namespaced";
                  }) version.resources
                );
              }) item.versions
            );
          }) data.items
        );
    in
    core' // aggregated';

  genRoots =
    with lib;
    swagger: namespaced:
    let
      refType = attr: head (tail (tail (splitString "/" attr."$ref")));

      refDefinition = attr: head (tail (tail (splitString "/" attr."$ref")));

      mapCharPairs =
        f: s1: s2:
        concatStrings (
          imap0 (i: c1: f i c1 (if i >= stringLength s2 then "" else elemAt (stringToCharacters s2) i)) (
            stringToCharacters s1
          )
        );

      getAttrName =
        resource: kind:
        mapCharPairs (
          i: c1: c2:
          if lib.hasPrefix "API" kind && i == 0 then
            "A"
          else if i == 0 then
            c1
          else if c2 == "" || (lib.toLower c2) != c1 then
            c1
          else
            c2
        ) resource kind;
    in
    mapAttrs'
      (
        name: path:
        let
          ref = refType (head path.post.parameters).schema;
          name' = last (splitString "/" name);
          group' = path.post."x-kubernetes-group-version-kind".group;
          group = if group' == "" then "core" else group';
          version = path.post."x-kubernetes-group-version-kind".version;
          kind = path.post."x-kubernetes-group-version-kind".kind;
          attrName = getAttrName name' kind;
        in
        nameValuePair ref {
          inherit
            ref
            attrName
            group
            version
            kind
            ;
          inherit (swagger.definitions.${ref}) description;

          name = name';
          definition = refDefinition (head path.post.parameters).schema;
          namespaced = attrByPath [ group version kind ] false namespaced;
        }
      )
      (
        filterAttrs (
          _name: path: hasAttr "post" path && path.post."x-kubernetes-action" == "post"
        ) swagger.paths
      );
in
src:
let
  swagger = lib.importJSON "${src}/api/openapi-spec/swagger.json";
in
{
  # The ports list in Container, EphemeralContainer
  # and ServiceSpec should not enforce "protocol".
  # See: https://github.com/arnarg/nixidy/issues/34
  specialMapKeys = {
    "io.k8s.api.core.v1.Container".ports = [ "containerPort" ];
    "io.k8s.api.core.v1.EphemeralContainer".ports = [ "containerPort" ];
    "io.k8s.api.core.v1.ServiceSpec".ports = [ "port" ];
  };

  schema = {
    definitions = swagger.definitions // {
      "io.k8s.apimachinery.pkg.api.resource.Quantity" = {
        inherit (swagger.definitions."io.k8s.apimachinery.pkg.api.resource.Quantity") description;
        oneOf = [
          { type = "string"; }
          { type = "number"; }
        ];
      };
    };
    roots = genRoots swagger (
      genNamespaced "${src}/api/discovery/api__v1.json" "${src}/api/discovery/aggregated_v2.json"
    );
  };
}
