# Based on kubenix's generator: https://github.com/hall/kubenix/blob/main/pkgs/generators/k8s/default.nix
{
  lib,
  schema,
  specialMapKeys ? { },
}:
with lib;
let
  # Escape ${...} sequences so they appear as literal text in generated
  # Nix "..." strings instead of being parsed as string interpolations.
  escapeNixStr = str: builtins.replaceStrings [ "\${" ] [ "\\$\{" ] str;

  toNixString =
    value:
    if isAttrs value || isList value then
      escapeNixStr (builtins.toJSON value)
    else if isString value then
      ''"${escapeNixStr value}"''
    else if value == null then
      "null"
    # Unary negation needs parentheses in function arguments and list elements.
    else if (isInt value || isFloat value) && value < 0 then
      "(${builtins.toString value})"
    else
      builtins.toString value;

  removeEmptyLines =
    str:
    concatStringsSep "\n" (filter (l: builtins.match "[[:space:]]*" l != [ ]) (splitString "\n" str));

  b = {
    types = {
      nullOr = val: "(types.nullOr ${val})";
      attrsOf = val: "(types.attrsOf ${val})";
      listOf = val: "(types.listOf ${val})";
      either = val1: val2: "(types.either ${val1} ${val2})";
      loaOf = type: "(types.loaOf ${type})";
      oneOf = ts: "(types.oneOf [${concatStringsSep " " ts}])";

      # Validators: take the scalar bound(s) and an already-rendered base type
      # string, and render the application as source. The names resolve to the
      # helpers inlined into the generated file's `let` block.
      withMinimum = min: base: "(types.withMinimum ${toNixString min} ${base})";
      withMaximum = max: base: "(types.withMaximum ${toNixString max} ${base})";
      withExclusiveMinimum = min: base: "(types.withExclusiveMinimum ${toNixString min} ${base})";
      withExclusiveMaximum = max: base: "(types.withExclusiveMaximum ${toNixString max} ${base})";
      withMultipleOf = m: base: "(types.withMultipleOf ${toNixString m} ${base})";
      withMinLength = n: base: "(types.withMinLength ${toString n} ${base})";
      withMaxLength = n: base: "(types.withMaxLength ${toString n} ${base})";
      # enum values are self-describing scalars; emit as a literal list.
      enum = vals: "(types.enum [${concatStringsSep " " (map toNixString vals)}])";
    };

    mkOption =
      {
        description ? null,
        type ? null,
        default ? null,
        apply ? null,
      }:
      removeEmptyLines ''
        mkOption {
              ${optionalString (
                description != null
              ) "description = ${escapeNixStr (builtins.toJSON description)};"}
              ${optionalString (type != null) "type = ${type};"}
              ${optionalString (default != null) "default = ${toNixString default};"}
              ${optionalString (apply != null) "apply = ${apply};"}
            }'';

    submoduleOf = ref: ''(submoduleOf "${ref}")'';

    globalSubmoduleOf = ref: ''(globalSubmoduleOf "${ref}")'';

    submoduleForDefinition =
      ref: name: kind: group: version:
      ''(submoduleForDefinition "${ref}" "${name}" "${kind}" "${group}" "${version}")'';

    coerceAttrsOfSubmodulesToListByKey =
      ref: attrMergeKey: listMergeKeys:
      ''(coerceAttrsOfSubmodulesToListByKey "${ref}" "${attrMergeKey}" [${
        concatStringsSep " " (map (key: "\"${toString key}\"") listMergeKeys)
      }])'';

    attrsToList = "attrsToList";
  };

  refDefinition = attr: head (tail (tail (splitString "/" attr."$ref")));

  hasTypeMapping =
    def:
    (def ? enum && all (v: isBool v || isString v || isInt v || isFloat v) def.enum)
    || (def ? oneOf && any hasTypeMapping def.oneOf)
    || (
      def ? type
      && elem def.type [
        "string"
        "integer"
        "boolean"
        "number"
        "any"
      ]
    );

  # Fold the JsonSchema validation keywords a def carries over its base type.
  withValidation =
    base: def:
    let
      steps = filter (s: s != null) [
        (if def ? minimum then b.types.withMinimum def.minimum else null)
        (if def ? maximum then b.types.withMaximum def.maximum else null)
        (
          if def ? exclusiveMinimum && !(isBool def.exclusiveMinimum) then
            b.types.withExclusiveMinimum def.exclusiveMinimum
          else
            null
        )
        (
          if def ? exclusiveMaximum && !(isBool def.exclusiveMaximum) then
            b.types.withExclusiveMaximum def.exclusiveMaximum
          else
            null
        )
        (if def ? multipleOf then b.types.withMultipleOf def.multipleOf else null)
        (if def ? minLength then b.types.withMinLength def.minLength else null)
        (if def ? maxLength then b.types.withMaxLength def.maxLength else null)
      ];
    in
    foldl' (t: f: f t) base steps;

  compareVersions =
    ver1: ver2:
    let
      getVersion = substring 1 10;
      splitVersion = v: builtins.splitVersion (getVersion v);
      isAlpha = v: elem "alpha" (splitVersion v);
      patchVersion =
        v:
        if isAlpha v then
          ""
        else if length (splitVersion v) == 1 then
          "${getVersion v}prod"
        else
          getVersion v;
    in
    builtins.compareVersions (patchVersion ver1) (patchVersion ver2);

  schemaDefs = schema.definitions;
  resourceTypes = schema.roots;

  resourceTypesByKind = zipAttrs (
    mapAttrsToList (_name: rt: {
      ${rt.kind} = rt;
    }) resourceTypes
  );
  latestResourceTypesByKind = mapAttrs (
    _kind: rts: head (sort (r1: r2: compareVersions r1.version r2.version > 0) rts)
  ) resourceTypesByKind;
  namespacedResourceTypes = filterAttrs (_: type: type.namespaced) resourceTypes;

  mapType =
    def:
    # enum short-circuits: the values are self-describing scalars and map
    # straight onto Nix's native `types.enum`.
    if def ? enum then
      b.types.enum def.enum
    else if def ? oneOf then
      b.types.oneOf (map mapType (filter hasTypeMapping def.oneOf))
    else if def ? type then
      if def.type == "string" then
        if def ? format && def.format == "int-or-string" then
          b.types.either "types.int" "types.str"
        else
          withValidation "types.str" def
      else if def.type == "integer" then
        withValidation "types.int" def
      else if def.type == "number" then
        withValidation (b.types.either "types.int" "types.float") def
      else if def.type == "boolean" then
        "types.bool"
      else if def.type == "object" then
        "types.attrs"
      else if def.type == "array" then
        b.types.listOf (mapType def.items)
      else if def.type == "any" then
        "types.unspecified"
      else
        throw "type ${def.type} not supported"
    else
      throw "unknown definition";

  definitions = mapAttrs (
    _name: definition:
    # an alias of another definition
    if definition ? "$ref" then
      schemaDefs.${refDefinition definition}
    else if !(definition ? properties) then
      { }
    else
      {
        options = mapAttrs (
          propName: property:
          let
            isRequired = elem propName (definition.required or [ ]);
            requiredOrNot = type: if isRequired then type else b.types.nullOr type;
            optionProperties =
              if property ? "$ref" then
                # Our special "#/global" ref prefix gets typed metadata from
                # the shared (config-level) definition set. See crd2jsonschema.py.
                if hasPrefix "#/global" property."$ref" then
                  { type = requiredOrNot (b.globalSubmoduleOf (refDefinition property)); }
                else if hasTypeMapping schemaDefs.${refDefinition property} then
                  { type = requiredOrNot (mapType schemaDefs.${refDefinition property}); }
                else
                  {
                    type =
                      if (refDefinition property) == _name then
                        "types.unspecified" # do not allow self-referential values
                      else
                        requiredOrNot (b.submoduleOf (refDefinition property));
                  }
              else if property.type == "array" then
                if property.items ? "$ref" then
                  if hasTypeMapping schemaDefs.${refDefinition property.items} then
                    { type = requiredOrNot (b.types.listOf (mapType schemaDefs.${refDefinition property.items})); }
                  # attrset of submodules merged by x-kubernetes-patch-merge-key
                  else if
                    (property ? "x-kubernetes-patch-merge-key")
                    && (
                      !(property ? "x-kubernetes-list-map-keys")
                      || (property."x-kubernetes-list-map-keys" == [ property."x-kubernetes-patch-merge-key" ])
                    )
                  then
                    let
                      mergeKey = property."x-kubernetes-patch-merge-key";
                    in
                    {
                      type = requiredOrNot (
                        b.coerceAttrsOfSubmodulesToListByKey (refDefinition property.items) mergeKey [ ]
                      );
                      apply = b.attrsToList;
                    }
                  # attrset of submodules merged by "name"
                  else if
                    schemaDefs.${refDefinition property.items} ? properties
                    && schemaDefs.${refDefinition property.items}.properties ? name
                  then
                    {
                      type = requiredOrNot (
                        b.coerceAttrsOfSubmodulesToListByKey (refDefinition property.items) "name" (
                          specialMapKeys.${_name}.${propName} or property."x-kubernetes-list-map-keys" or [ ]
                        )
                      );
                      apply = b.attrsToList;
                    }
                  else
                    {
                      type =
                        if (refDefinition property.items) == _name then
                          "types.unspecified" # do not allow self-referential values
                        else
                          requiredOrNot (b.types.listOf (b.submoduleOf (refDefinition property.items)));
                    }
                else
                  { type = requiredOrNot (b.types.listOf (mapType property.items)); }
              else if property.type == "object" && property ? additionalProperties then
                if
                  (
                    property.additionalProperties ? "$ref"
                    && hasTypeMapping schemaDefs.${refDefinition property.additionalProperties}
                  )
                then
                  {
                    type = requiredOrNot (
                      b.types.attrsOf (mapType schemaDefs.${refDefinition property.additionalProperties})
                    );
                  }
                else if property.additionalProperties ? "$ref" then
                  { type = requiredOrNot "types.attrs"; }
                else if property.additionalProperties.type == "array" then
                  { type = requiredOrNot (b.types.loaOf (mapType property.additionalProperties.items)); }
                else
                  { type = requiredOrNot (b.types.attrsOf (mapType property.additionalProperties)); }
              else
                { type = requiredOrNot (mapType property); };
          in
          b.mkOption (
            {
              description = property.description or "";
            }
            // optionProperties
          )
        ) definition.properties;

        config =
          let
            optionalProps = filterAttrs (
              propName: _property: !(elem propName (definition.required or [ ]))
            ) definition.properties;
          in
          mapAttrs (_name: _property: "mkOverride 1002 null") optionalProps;
      }
  ) schemaDefs;

  genResourceOptions =
    resource:
    b.mkOption {
      inherit (resource) description;
      type = b.types.attrsOf (
        b.submoduleForDefinition resource.ref resource.name resource.kind resource.group resource.version
      );
      default = { };
    };

  generated = ''
    # This file was generated with nixidy resource generator, do not edit.
    { lib, options, config, ... }:

    with lib;

    let
      hasAttrNotNull = attr: set: hasAttr attr set && set.''${attr} != null;

      attrsToList = values:
        if values != null
        then
          sort (a: b:
            if (hasAttrNotNull "_priority" a && hasAttrNotNull "_priority" b)
            then a._priority < b._priority
            else false
          ) (mapAttrsToList (n: v: v) values)
        else
          values;

      getDefaults = resource: group: version: kind:
        catAttrs "default" (filter (default:
          (default.resource == null || default.resource == resource) &&
          (default.group == null || default.group == group) &&
          (default.version == null || default.version == version) &&
          (default.kind == null || default.kind == kind)
        ) config.defaults);

      types = lib.types // rec {
        str = mkOptionType {
          name = "str";
          description = "string";
          check = isString;
          merge = mergeEqualOption;
        };

        # Either value of type `finalType` or `coercedType`, the latter is
        # converted to `finalType` using `coerceFunc`.
        coercedTo = coercedType: coerceFunc: finalType:
        mkOptionType rec {
          inherit (finalType) getSubOptions getSubModules;

          name = "coercedTo";
          description = "''${finalType.description} or ''${coercedType.description}";
          check = x: finalType.check x || coercedType.check x;
          merge = loc: defs:
            let
              coerceVal = val:
                if finalType.check val then val
                else let
                  coerced = coerceFunc val;
                in assert finalType.check coerced; coerced;

            in finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
          substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
          typeMerge = t1: t2: null;
          functor = (defaultFunctor name) // { wrapped = finalType; };
        };

        # Numeric bounds.
        withMinimum =
          min: base:
          lib.types.addCheck base (x: x >= min)
          // {
            description = "''${base.description} (minimum ''${toString min})";
          };
        withMaximum =
          max: base:
          lib.types.addCheck base (x: x <= max)
          // {
            description = "''${base.description} (maximum ''${toString max})";
          };
        withExclusiveMinimum =
          min: base:
          lib.types.addCheck base (x: x > min)
          // {
            description = "''${base.description} (exclusive minimum ''${toString min})";
          };
        withExclusiveMaximum =
          max: base:
          lib.types.addCheck base (x: x < max)
          // {
            description = "''${base.description} (exclusive maximum ''${toString max})";
          };
        withMultipleOf =
          m: base:
          lib.types.addCheck base (x: mod x m == 0)
          // {
            description = "''${base.description} (multiple of ''${toString m})";
          };

        # String constraints.
        withMinLength =
          n: base:
          lib.types.addCheck base (x: stringLength x >= n)
          // {
            description = "''${base.description} (min length ''${toString n})";
          };
        withMaxLength =
          n: base:
          lib.types.addCheck base (x: stringLength x <= n)
          // {
            description = "''${base.description} (max length ''${toString n})";
          };
      };

      mkOptionDefault = mkOverride 1001;

      mergeValuesByKey = attrMergeKey: listMergeKeys: values:
        listToAttrs (imap0
          (i: value: nameValuePair (
            if hasAttr attrMergeKey value
            then
              if isAttrs value.''${attrMergeKey}
              then toString value.''${attrMergeKey}.content
              else (toString value.''${attrMergeKey})
            else
              # generate merge key for list elements if it's not present
              "__kubenix_list_merge_key_" + (concatStringsSep "" (map (key:
                if isAttrs value.''${key}
                then toString value.''${key}.content
                else (toString value.''${key})
              ) listMergeKeys))
          ) (value // { _priority = i; }))
        values);

      submoduleOf = ref: types.submodule ({name, ...}: {
        options = definitions."''${ref}".options or {};
        config = definitions."''${ref}".config or {};
      });

      globalSubmoduleOf = ref: types.submodule ({name, ...}: {
        options = config.definitions."''${ref}".options or {};
        config = config.definitions."''${ref}".config or {};
      });

      submoduleWithMergeOf = ref: mergeKey: types.submodule ({name, ...}: let
        convertName = name:
          if definitions."''${ref}".options.''${mergeKey}.type == types.int
          then toInt name
          else name;
      in {
        options = definitions."''${ref}".options // {
          # position in original array
          _priority = mkOption { type = types.nullOr types.int; default = null; internal = true; };
        };
        config = definitions."''${ref}".config // {
          ''${mergeKey} = mkOverride 1002 (
            # use name as mergeKey only if it is not coming from mergeValuesByKey
            if (!hasPrefix "__kubenix_list_merge_key_" name)
            then convertName name
            else null
          );
        };
      });

      submoduleForDefinition = ref: resource: kind: group: version: let
        apiVersion = if group == "core" then version else "''${group}/''${version}";
      in types.submodule ({name, ...}: {
        inherit (definitions."''${ref}") options;

        imports = getDefaults resource group version kind;
        config = mkMerge [
          definitions."''${ref}".config
          {
            kind = mkOptionDefault kind;
            apiVersion = mkOptionDefault apiVersion;

            # metdata.name cannot use option default, due deep config
            metadata.name = mkOptionDefault name;
          }
        ];
      });

      coerceAttrsOfSubmodulesToListByKey = ref: attrMergeKey: listMergeKeys: (types.coercedTo
        (types.listOf (submoduleOf ref))
        (mergeValuesByKey attrMergeKey listMergeKeys)
        (types.attrsOf (submoduleWithMergeOf ref attrMergeKey))
      );

      definitions = {
        ${concatStrings (
          mapAttrsToList (name: value: ''
            "${name}" = {
              ${optionalString (hasAttr "options" value) "
            options = {${
                            concatStrings (
                              mapAttrsToList (name: value: ''
                                "${name}" = ${value};
                              '') value.options
                            )
                          }};
            "}

              ${optionalString (hasAttr "config" value) ''
                config = {${
                  concatStrings (
                    mapAttrsToList (name: value: ''
                      "${name}" = ${value};
                    '') value.config
                  )
                }};
              ''}
            };
          '') definitions
        )}
      };
    in {
      # all resource versions
      options = {
        resources = {
          ${concatStrings (
            mapAttrsToList (_: rt: ''
              "${rt.group}"."${rt.version}"."${rt.kind}" = ${genResourceOptions rt};
            '') resourceTypes
          )}
        } // {
          ${concatStrings (
            mapAttrsToList (_: rt: ''
              "${rt.attrName}" = ${genResourceOptions rt};
            '') latestResourceTypesByKind
          )}
        };
      };

      config = {
        # expose resource definitions
        inherit definitions;

        # register resource types
        types = [${
          concatStrings (
            mapAttrsToList (_: rt: ''
              {
                        name = "${rt.name}";
                        group = "${rt.group}";
                        version = "${rt.version}";
                        kind = "${rt.kind}";
                        attrName = "${rt.attrName}";
                      }'') resourceTypes
          )
        }];

        resources = {
          ${concatStrings (
            mapAttrsToList (_: rt: ''
              "${rt.group}"."${rt.version}"."${rt.kind}" =
                mkAliasDefinitions options.resources."${rt.attrName}";
            '') latestResourceTypesByKind
          )}
        };

        # make all namespaced resources default to the
        # application's namespace
        defaults = [${
          concatStrings (
            mapAttrsToList (_: rt: ''
              {
                  group = "${rt.group}";
                  version = "${rt.version}";
                  kind = "${rt.kind}";
                  default.metadata.namespace = lib.mkDefault config.namespace;
                }'') namespacedResourceTypes
          )
        }];
      };
    }
  '';
in
generated
