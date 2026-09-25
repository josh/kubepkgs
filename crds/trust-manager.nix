# This file was generated with nixidy resource generator, do not edit.
{
  lib,
  options,
  config,
  ...
}:

with lib;

let
  hasAttrNotNull = attr: set: hasAttr attr set && set.${attr} != null;

  attrsToList =
    values:
    if values != null then
      sort (
        a: b:
        if (hasAttrNotNull "_priority" a && hasAttrNotNull "_priority" b) then
          a._priority < b._priority
        else
          false
      ) (mapAttrsToList (n: v: v) values)
    else
      values;

  getDefaults =
    resource: group: version: kind:
    catAttrs "default" (
      filter (
        default:
        (default.resource == null || default.resource == resource)
        && (default.group == null || default.group == group)
        && (default.version == null || default.version == version)
        && (default.kind == null || default.kind == kind)
      ) config.defaults
    );

  types = lib.types // rec {
    str = mkOptionType {
      name = "str";
      description = "string";
      check = isString;
      merge = mergeEqualOption;
    };

    # Either value of type `finalType` or `coercedType`, the latter is
    # converted to `finalType` using `coerceFunc`.
    coercedTo =
      coercedType: coerceFunc: finalType:
      mkOptionType rec {
        inherit (finalType) getSubOptions getSubModules;

        name = "coercedTo";
        description = "${finalType.description} or ${coercedType.description}";
        check = x: finalType.check x || coercedType.check x;
        merge =
          loc: defs:
          let
            coerceVal =
              val:
              if finalType.check val then
                val
              else
                let
                  coerced = coerceFunc val;
                in
                assert finalType.check coerced;
                coerced;

          in
          finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
        substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
        typeMerge = t1: t2: null;
        functor = (defaultFunctor name) // {
          wrapped = finalType;
        };
      };

    # Numeric bounds.
    withMinimum =
      min: base:
      lib.types.addCheck base (x: x >= min)
      // {
        description = "${base.description} (minimum ${toString min})";
      };
    withMaximum =
      max: base:
      lib.types.addCheck base (x: x <= max)
      // {
        description = "${base.description} (maximum ${toString max})";
      };
    withExclusiveMinimum =
      min: base:
      lib.types.addCheck base (x: x > min)
      // {
        description = "${base.description} (exclusive minimum ${toString min})";
      };
    withExclusiveMaximum =
      max: base:
      lib.types.addCheck base (x: x < max)
      // {
        description = "${base.description} (exclusive maximum ${toString max})";
      };
    withMultipleOf =
      m: base:
      lib.types.addCheck base (x: mod x m == 0)
      // {
        description = "${base.description} (multiple of ${toString m})";
      };

    # String constraints.
    withMinLength =
      n: base:
      lib.types.addCheck base (x: stringLength x >= n)
      // {
        description = "${base.description} (min length ${toString n})";
      };
    withMaxLength =
      n: base:
      lib.types.addCheck base (x: stringLength x <= n)
      // {
        description = "${base.description} (max length ${toString n})";
      };
  };

  mkOptionDefault = mkOverride 1001;

  mergeValuesByKey =
    attrMergeKey: listMergeKeys: values:
    listToAttrs (
      imap0 (
        i: value:
        nameValuePair (
          if hasAttr attrMergeKey value then
            if isAttrs value.${attrMergeKey} then
              toString value.${attrMergeKey}.content
            else
              (toString value.${attrMergeKey})
          else
            # generate merge key for list elements if it's not present
            "__kubenix_list_merge_key_"
            + (concatStringsSep "" (
              map (
                key: if isAttrs value.${key} then toString value.${key}.content else (toString value.${key})
              ) listMergeKeys
            ))
        ) (value // { _priority = i; })
      ) values
    );

  submoduleOf =
    ref:
    types.submodule (
      { name, ... }:
      {
        options = definitions."${ref}".options or { };
        config = definitions."${ref}".config or { };
      }
    );

  globalSubmoduleOf =
    ref:
    types.submodule (
      { name, ... }:
      {
        options = config.definitions."${ref}".options or { };
        config = config.definitions."${ref}".config or { };
      }
    );

  submoduleWithMergeOf =
    ref: mergeKey:
    types.submodule (
      { name, ... }:
      let
        convertName =
          name: if definitions."${ref}".options.${mergeKey}.type == types.int then toInt name else name;
      in
      {
        options = definitions."${ref}".options // {
          # position in original array
          _priority = mkOption {
            type = types.nullOr types.int;
            default = null;
            internal = true;
          };
        };
        config = definitions."${ref}".config // {
          ${mergeKey} = mkOverride 1002 (
            # use name as mergeKey only if it is not coming from mergeValuesByKey
            if (!hasPrefix "__kubenix_list_merge_key_" name) then convertName name else null
          );
        };
      }
    );

  submoduleForDefinition =
    ref: resource: kind: group: version:
    let
      apiVersion = if group == "core" then version else "${group}/${version}";
    in
    types.submodule (
      { name, ... }:
      {
        inherit (definitions."${ref}") options;

        imports = getDefaults resource group version kind;
        config = mkMerge [
          definitions."${ref}".config
          {
            kind = mkOptionDefault kind;
            apiVersion = mkOptionDefault apiVersion;

            # metdata.name cannot use option default, due deep config
            metadata.name = mkOptionDefault name;
          }
        ];
      }
    );

  coerceAttrsOfSubmodulesToListByKey =
    ref: attrMergeKey: listMergeKeys:
    (types.coercedTo (types.listOf (submoduleOf ref)) (mergeValuesByKey attrMergeKey listMergeKeys) (
      types.attrsOf (submoduleWithMergeOf ref attrMergeKey)
    ));

  definitions = {
    "trust.cert-manager.io.v1alpha1.Bundle" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "spec represents the desired state of the Bundle resource.";
          type = (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpec");
        };
        "status" = mkOption {
          description = "status of the Bundle. This is set and managed automatically.";
          type = (types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpec" = {

      options = {
        "sources" = mkOption {
          description = "sources is a set of references to data whose data will sync to the target.";
          type = (types.listOf (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecSources"));
        };
        "target" = mkOption {
          description = "target is the target location in all namespaces to sync source data to.";
          type = (types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecTarget"));
        };
      };

      config = {
        "target" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecSources" = {

      options = {
        "configMap" = mkOption {
          description = "configMap is a reference (by name) to a ConfigMap's `data` key(s), or to a\nlist of ConfigMap's `data` key(s) using label selector, in the trust namespace.";
          type = (types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecSourcesConfigMap"));
        };
        "inLine" = mkOption {
          description = "inLine is a simple string to append as the source data.";
          type = (types.nullOr (types.withMaxLength 1048576 (types.withMinLength 1 types.str)));
        };
        "secret" = mkOption {
          description = "secret is a reference (by name) to a Secret's `data` key(s), or to a\nlist of Secret's `data` key(s) using label selector, in the trust namespace.";
          type = (types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecSourcesSecret"));
        };
        "useDefaultCAs" = mkOption {
          description = "useDefaultCAs indicates whether the default CA bundle should be used as a source.\nThe default CA bundle is available only if trust-manager was installed with\ndefault CA support enabled, either via the Helm chart or by starting the\ntrust-manager controller with the \"--default-package-location\" flag.\nIf default CA support was not enabled at startup, setting this field to true\nwill result in reconciliation failure.\nThe version of the default CA package used for this Bundle is reported in\nstatus.defaultCAVersion.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "configMap" = mkOverride 1002 null;
        "inLine" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
        "useDefaultCAs" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecSourcesConfigMap" = {

      options = {
        "includeAllKeys" = mkOption {
          description = "includeAllKeys is a flag to include all keys in the object's `data` field to be used. False by default.\nThis field must not be true when `key` is set.";
          type = (types.nullOr types.bool);
        };
        "key" = mkOption {
          description = "key of the entry in the object's `data` field to be used.";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
        "name" = mkOption {
          description = "name is the name of the source object in the trust namespace.\nThis field must be left empty when `selector` is set";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
        "selector" = mkOption {
          description = "selector is the label selector to use to fetch a list of objects. Must not be set\nwhen `name` is set.";
          type = (
            types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecSourcesConfigMapSelector")
          );
        };
      };

      config = {
        "includeAllKeys" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecSourcesConfigMapSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecSourcesConfigMapSelectorMatchExpressions"
              )
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecSourcesConfigMapSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecSourcesSecret" = {

      options = {
        "includeAllKeys" = mkOption {
          description = "includeAllKeys is a flag to include all keys in the object's `data` field to be used. False by default.\nThis field must not be true when `key` is set.";
          type = (types.nullOr types.bool);
        };
        "key" = mkOption {
          description = "key of the entry in the object's `data` field to be used.";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
        "name" = mkOption {
          description = "name is the name of the source object in the trust namespace.\nThis field must be left empty when `selector` is set";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
        "selector" = mkOption {
          description = "selector is the label selector to use to fetch a list of objects. Must not be set\nwhen `name` is set.";
          type = (
            types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecSourcesSecretSelector")
          );
        };
      };

      config = {
        "includeAllKeys" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecSourcesSecretSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecSourcesSecretSelectorMatchExpressions"
              )
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecSourcesSecretSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecTarget" = {

      options = {
        "additionalFormats" = mkOption {
          description = "additionalFormats specifies any additional formats to write to the target";
          type = (
            types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecTargetAdditionalFormats")
          );
        };
        "configMap" = mkOption {
          description = "configMap is the target ConfigMap in Namespaces that all Bundle source\ndata will be synced to.";
          type = (types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecTargetConfigMap"));
        };
        "namespaceSelector" = mkOption {
          description = "namespaceSelector will, if set, only sync the target resource in\nNamespaces which match the selector.";
          type = (
            types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecTargetNamespaceSelector")
          );
        };
        "secret" = mkOption {
          description = "secret is the target Secret that all Bundle source data will be synced to.\nUsing Secrets as targets is only supported if enabled at trust-manager startup.\nBy default, trust-manager has no permissions for writing to secrets and can only read secrets in the trust namespace.";
          type = (types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecTargetSecret"));
        };
      };

      config = {
        "additionalFormats" = mkOverride 1002 null;
        "configMap" = mkOverride 1002 null;
        "namespaceSelector" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecTargetAdditionalFormats" = {

      options = {
        "jks" = mkOption {
          description = "jks requests a JKS-formatted binary trust bundle to be written to the target.\nThe bundle has \"changeit\" as the default password.\nFor more information refer to this link https://cert-manager.io/docs/faq/#keystore-passwords\nFormat is deprecated: Writing JKS is subject for removal. Please migrate to PKCS12.\nPKCS#12 trust stores created by trust-manager are compatible with Java.";
          type = (
            types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecTargetAdditionalFormatsJks")
          );
        };
        "pkcs12" = mkOption {
          description = "pkcs12 requests a PKCS12-formatted binary trust bundle to be written to the target.\n\nThe bundle is by default created without a password.\nFor more information refer to this link https://cert-manager.io/docs/faq/#keystore-passwords";
          type = (
            types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecTargetAdditionalFormatsPkcs12")
          );
        };
      };

      config = {
        "jks" = mkOverride 1002 null;
        "pkcs12" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecTargetAdditionalFormatsJks" = {

      options = {
        "key" = mkOption {
          description = "key is the key of the entry in the object's `data` field to be used.";
          type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
        };
        "password" = mkOption {
          description = "password for JKS trust store";
          type = (types.nullOr (types.withMaxLength 128 (types.withMinLength 1 types.str)));
        };
      };

      config = {
        "password" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecTargetAdditionalFormatsPkcs12" = {

      options = {
        "key" = mkOption {
          description = "key is the key of the entry in the object's `data` field to be used.";
          type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
        };
        "password" = mkOption {
          description = "password for PKCS12 trust store";
          type = (types.nullOr (types.withMaxLength 128 (types.withMinLength 0 types.str)));
        };
        "profile" = mkOption {
          description = "profile specifies the certificate encryption algorithms and the HMAC algorithm\nused to create the PKCS12 trust store.\n\nIf provided, allowed values are:\n`LegacyRC2`: Deprecated. Not supported by default in OpenSSL 3 or Java 20.\n`LegacyDES`: Less secure algorithm. Use this option for maximal compatibility.\n`Modern2023`: Secure algorithm. Use this option in case you have to always use secure algorithms (e.g. because of company policy).\n\nDefault value is `LegacyRC2` for backward compatibility.";
          type = (
            types.nullOr (
              types.enum [
                "LegacyRC2"
                "LegacyDES"
                "Modern2023"
              ]
            )
          );
        };
      };

      config = {
        "password" = mkOverride 1002 null;
        "profile" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecTargetConfigMap" = {

      options = {
        "key" = mkOption {
          description = "key is the key of the entry in the object's `data` field to be used.";
          type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
        };
        "metadata" = mkOption {
          description = "metadata is an optional set of labels and annotations to be copied to the target.";
          type = (
            types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecTargetConfigMapMetadata")
          );
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecTargetConfigMapMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "annotations is a key value map to be copied to the target.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "labels is a key value map to be copied to the target.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecTargetNamespaceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecTargetNamespaceSelectorMatchExpressions"
              )
            )
          );
        };
        "matchLabels" = mkOption {
          description = "matchLabels is a map of {key,value} pairs. A single {key,value} in the matchLabels\nmap is equivalent to an element of matchExpressions, whose key field is \"key\", the\noperator is \"In\", and the values array contains only \"value\". The requirements are ANDed.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecTargetNamespaceSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "key is the label key that the selector applies to.";
          type = types.str;
        };
        "operator" = mkOption {
          description = "operator represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists and DoesNotExist.";
          type = types.str;
        };
        "values" = mkOption {
          description = "values is an array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. This array is replaced during a strategic\nmerge patch.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecTargetSecret" = {

      options = {
        "key" = mkOption {
          description = "key is the key of the entry in the object's `data` field to be used.";
          type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
        };
        "metadata" = mkOption {
          description = "metadata is an optional set of labels and annotations to be copied to the target.";
          type = (types.nullOr (submoduleOf "trust.cert-manager.io.v1alpha1.BundleSpecTargetSecretMetadata"));
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleSpecTargetSecretMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "annotations is a key value map to be copied to the target.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "labels is a key value map to be copied to the target.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleStatus" = {

      options = {
        "conditions" = mkOption {
          description = "conditions represent the latest available observations of the Bundle's current state.";
          type = (
            types.nullOr (types.listOf (submoduleOf "trust.cert-manager.io.v1alpha1.BundleStatusConditions"))
          );
        };
        "defaultCAVersion" = mkOption {
          description = "defaultCAVersion is the version of the default CA package used when resolving\nthe default CA source(s) for this Bundle (for example, when any source has\nuseDefaultCAs set to true), if applicable.\nBundles resolved from identical sets of default CA certificates will report\nthe same defaultCAVersion value.";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "defaultCAVersion" = mkOverride 1002 null;
      };

    };
    "trust.cert-manager.io.v1alpha1.BundleStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "lastTransitionTime is the last time the condition transitioned from one status to another.\nThis should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.";
          type = types.str;
        };
        "message" = mkOption {
          description = "message is a human readable message indicating details about the transition.\nThis may be an empty string.";
          type = (types.withMaxLength 32768 types.str);
        };
        "observedGeneration" = mkOption {
          description = "observedGeneration represents the .metadata.generation that the condition was set based upon.\nFor instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date\nwith respect to the current state of the instance.";
          type = (types.nullOr (types.withMinimum 0 types.int));
        };
        "reason" = mkOption {
          description = "reason contains a programmatic identifier indicating the reason for the condition's last transition.\nProducers of specific condition types may define expected values and meanings for this field,\nand whether the values are considered a guaranteed API.\nThe value should be a CamelCase string.\nThis field may not be empty.";
          type = (types.withMaxLength 1024 (types.withMinLength 1 types.str));
        };
        "status" = mkOption {
          description = "status of the condition, one of True, False, Unknown.";
          type = (
            types.enum [
              "True"
              "False"
              "Unknown"
            ]
          );
        };
        "type" = mkOption {
          description = "type of condition in CamelCase or in foo.example.com/CamelCase.";
          type = (types.withMaxLength 316 types.str);
        };
      };

      config = {
        "observedGeneration" = mkOverride 1002 null;
      };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "trust.cert-manager.io"."v1alpha1"."Bundle" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "trust.cert-manager.io.v1alpha1.Bundle" "bundles" "Bundle"
              "trust.cert-manager.io"
              "v1alpha1"
          )
        );
        default = { };
      };

    }
    // {
      "bundles" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "trust.cert-manager.io.v1alpha1.Bundle" "bundles" "Bundle"
              "trust.cert-manager.io"
              "v1alpha1"
          )
        );
        default = { };
      };

    };
  };

  config = {
    # expose resource definitions
    inherit definitions;

    # register resource types
    types = [
      {
        name = "bundles";
        group = "trust.cert-manager.io";
        version = "v1alpha1";
        kind = "Bundle";
        attrName = "bundles";
      }
    ];

    resources = {
      "trust.cert-manager.io"."v1alpha1"."Bundle" = mkAliasDefinitions options.resources."bundles";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [ ];
  };
}
