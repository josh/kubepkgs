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
    "grafana.integreatly.org.v1beta1.Grafana" = {

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
          description = "GrafanaSpec defines the desired state of Grafana";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpec");
        };
        "status" = mkOption {
          description = "GrafanaStatus defines the observed state of Grafana";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroup" = {

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
          description = "GrafanaAlertRuleGroupSpec defines the desired state of GrafanaAlertRuleGroup";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpec");
        };
        "status" = mkOption {
          description = "The most recent observed state of a Grafana resource";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpec" = {

      options = {
        "allowCrossNamespaceImport" = mkOption {
          description = "Allow the Operator to match this resource with Grafanas outside the current namespace";
          type = (types.nullOr types.bool);
        };
        "editable" = mkOption {
          description = "Whether to enable or disable editing of the alert rule group in Grafana UI";
          type = (types.nullOr types.bool);
        };
        "folderRef" = mkOption {
          description = "Match GrafanaFolders CRs to infer the uid";
          type = (types.nullOr types.str);
        };
        "folderUID" = mkOption {
          description = "UID of the folder containing this rule group\nOverrides the FolderSelector";
          type = (types.nullOr types.str);
        };
        "instanceSelector" = mkOption {
          description = "Selects Grafana instances for import";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecInstanceSelector");
        };
        "interval" = mkOption {
          description = "";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the alert rule group. If not specified, the resource name will be used.";
          type = (types.nullOr types.str);
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "rules" = mkOption {
          description = "";
          type = (
            types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecRules")
          );
        };
        "suspend" = mkOption {
          description = "Suspend pauses synchronizing attempts and tells the operator to ignore changes";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "allowCrossNamespaceImport" = mkOverride 1002 null;
        "editable" = mkOverride 1002 null;
        "folderRef" = mkOverride 1002 null;
        "folderUID" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecInstanceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecInstanceSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecInstanceSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecRules" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "condition" = mkOption {
          description = "";
          type = types.str;
        };
        "dashboardUid" = mkOption {
          description = "Deprecated: The field is not used, use rules[].annotations.__dashboardUid__";
          type = (types.nullOr types.str);
        };
        "data" = mkOption {
          description = "";
          type = (
            types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecRulesData")
          );
        };
        "execErrState" = mkOption {
          description = "";
          type = (
            types.enum [
              "OK"
              "Alerting"
              "Error"
              "KeepLast"
            ]
          );
        };
        "for" = mkOption {
          description = "";
          type = types.str;
        };
        "isPaused" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "keepFiringFor" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "missingSeriesEvalsToResolve" = mkOption {
          description = "The number of missing series evaluations that must occur before the rule is considered to be resolved.";
          type = (types.nullOr types.int);
        };
        "noDataState" = mkOption {
          description = "";
          type = (
            types.enum [
              "Alerting"
              "NoData"
              "OK"
              "KeepLast"
            ]
          );
        };
        "notificationSettings" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecRulesNotificationSettings"
            )
          );
        };
        "panelId" = mkOption {
          description = "Deprecated: The field is not used, use rules[].annotations.__panelId__";
          type = (types.nullOr types.int);
        };
        "record" = mkOption {
          description = "";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecRulesRecord")
          );
        };
        "title" = mkOption {
          description = "";
          type = (types.withMaxLength 190 (types.withMinLength 1 types.str));
        };
        "uid" = mkOption {
          description = "UID of the alert rule. Can be any string consisting of alphanumeric characters, - and _ with a maximum length of 40";
          type = (types.withMaxLength 40 types.str);
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "dashboardUid" = mkOverride 1002 null;
        "isPaused" = mkOverride 1002 null;
        "keepFiringFor" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
        "missingSeriesEvalsToResolve" = mkOverride 1002 null;
        "notificationSettings" = mkOverride 1002 null;
        "panelId" = mkOverride 1002 null;
        "record" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecRulesData" = {

      options = {
        "datasourceUid" = mkOption {
          description = "Grafana data source unique identifier; it should be '__expr__' for a Server Side Expression operation.";
          type = (types.nullOr types.str);
        };
        "model" = mkOption {
          description = "JSON is the raw JSON query and includes the above properties as well as custom properties.";
          type = (types.nullOr types.unspecified);
        };
        "queryType" = mkOption {
          description = "QueryType is an optional identifier for the type of query.\nIt can be used to distinguish different types of queries.";
          type = (types.nullOr types.str);
        };
        "refId" = mkOption {
          description = "RefID is the unique identifier of the query, set by the frontend call.";
          type = (types.nullOr types.str);
        };
        "relativeTimeRange" = mkOption {
          description = "relative time range";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecRulesDataRelativeTimeRange"
            )
          );
        };
      };

      config = {
        "datasourceUid" = mkOverride 1002 null;
        "model" = mkOverride 1002 null;
        "queryType" = mkOverride 1002 null;
        "refId" = mkOverride 1002 null;
        "relativeTimeRange" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecRulesDataRelativeTimeRange" = {

      options = {
        "from" = mkOption {
          description = "from";
          type = (types.nullOr types.int);
        };
        "to" = mkOption {
          description = "to";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "from" = mkOverride 1002 null;
        "to" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecRulesNotificationSettings" = {

      options = {
        "active_time_intervals" = mkOption {
          description = "ActiveTimeIntervals defines the time intervals during which notifications should NOT be muted.";
          type = (types.nullOr (types.listOf types.str));
        };
        "group_by" = mkOption {
          description = "GroupBy defines the labels by which incoming alerts are grouped together.";
          type = (types.nullOr (types.listOf types.str));
        };
        "group_interval" = mkOption {
          description = "GroupInterval defines how long to wait before sending a notification about new alerts added\nto a group for which an initial notification has already been sent. (e.g. 5m)";
          type = (types.nullOr types.str);
        };
        "group_wait" = mkOption {
          description = "GroupWait defines how long to initially wait to send a notification for a group of alerts. (e.g. 30s)";
          type = (types.nullOr types.str);
        };
        "mute_time_intervals" = mkOption {
          description = "MuteTimeIntervals defines the time intervals during which notifications should be muted.\nThese must match the name of a mute time interval defined in the Alertmanager configuration.";
          type = (types.nullOr (types.listOf types.str));
        };
        "receiver" = mkOption {
          description = "Receiver is the name of the receiver to send notifications to.";
          type = (types.withMinLength 1 types.str);
        };
        "repeat_interval" = mkOption {
          description = "RepeatInterval defines how long to wait before sending a notification again if it has already\nbeen sent successfully for an alert. (e.g. 4h)\nShould not be less than GroupInterval.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "active_time_intervals" = mkOverride 1002 null;
        "group_by" = mkOverride 1002 null;
        "group_interval" = mkOverride 1002 null;
        "group_wait" = mkOverride 1002 null;
        "mute_time_intervals" = mkOverride 1002 null;
        "repeat_interval" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupSpecRulesRecord" = {

      options = {
        "from" = mkOption {
          description = "";
          type = types.str;
        };
        "metric" = mkOption {
          description = "";
          type = types.str;
        };
        "targetDatasourceUid" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "targetDatasourceUid" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupStatusConditions")
            )
          );
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroupStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaContactPoint" = {

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
          description = "GrafanaContactPointSpec defines the desired state of GrafanaContactPoint";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpec");
        };
        "status" = mkOption {
          description = "The most recent observed state of a Grafana resource";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpec" = {

      options = {
        "allowCrossNamespaceImport" = mkOption {
          description = "Allow the Operator to match this resource with Grafanas outside the current namespace";
          type = (types.nullOr types.bool);
        };
        "disableResolveMessage" = mkOption {
          description = "Deprecated: define the receiver under .spec.receivers[]\nWill be removed in a later version";
          type = (types.nullOr types.bool);
        };
        "editable" = mkOption {
          description = "Whether to enable or disable editing of the contact point in Grafana UI";
          type = (types.nullOr types.bool);
        };
        "instanceSelector" = mkOption {
          description = "Selects Grafana instances for import";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecInstanceSelector");
        };
        "name" = mkOption {
          description = "Receivers are grouped under the same ContactPoint using the Name\nDefaults to the name of the CR";
          type = (types.nullOr types.str);
        };
        "receivers" = mkOption {
          description = "List of receivers that Grafana will fan out notifications to";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecReceivers")
            )
          );
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "settings" = mkOption {
          description = "Deprecated: define the receiver under .spec.receivers[]\nWill be removed in a later version";
          type = (types.nullOr types.unspecified);
        };
        "suspend" = mkOption {
          description = "Suspend pauses synchronizing attempts and tells the operator to ignore changes";
          type = (types.nullOr types.bool);
        };
        "type" = mkOption {
          description = "Deprecated: define the receiver under .spec.receivers[]\nWill be removed in a later version";
          type = (types.nullOr (types.withMinLength 1 types.str));
        };
        "uid" = mkOption {
          description = "Deprecated: define the receiver under .spec.receivers[]\nManually specify the UID the Contact Point is created with. Can be any string consisting of alphanumeric characters, - and _ with a maximum length of 40";
          type = (types.nullOr (types.withMaxLength 40 types.str));
        };
        "valuesFrom" = mkOption {
          description = "Deprecated: define the receiver under .spec.receivers[]\nWill be removed in a later version";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecValuesFrom")
            )
          );
        };
      };

      config = {
        "allowCrossNamespaceImport" = mkOverride 1002 null;
        "disableResolveMessage" = mkOverride 1002 null;
        "editable" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "receivers" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "settings" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
        "valuesFrom" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecInstanceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecInstanceSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecInstanceSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecReceivers" = {

      options = {
        "disableResolveMessage" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "settings" = mkOption {
          description = "";
          type = types.unspecified;
        };
        "type" = mkOption {
          description = "";
          type = (types.withMinLength 1 types.str);
        };
        "uid" = mkOption {
          description = "Manually specify the UID the Contact Point is created with. Can be any string consisting of alphanumeric characters, - and _ with a maximum length of 40";
          type = (types.nullOr (types.withMaxLength 40 types.str));
        };
        "valuesFrom" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecReceiversValuesFrom"
              )
            )
          );
        };
      };

      config = {
        "disableResolveMessage" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
        "valuesFrom" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecReceiversValuesFrom" = {

      options = {
        "targetPath" = mkOption {
          description = "";
          type = types.str;
        };
        "valueFrom" = mkOption {
          description = "";
          type = (
            submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecReceiversValuesFromValueFrom"
          );
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecReceiversValuesFromValueFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecReceiversValuesFromValueFromConfigMapKeyRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecReceiversValuesFromValueFromSecretKeyRef"
            )
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecReceiversValuesFromValueFromConfigMapKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "The key to select.";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "Specify whether the ConfigMap or its key must be defined";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecReceiversValuesFromValueFromSecretKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "The key of the secret to select from.  Must be a valid secret key.";
            type = types.str;
          };
          "name" = mkOption {
            description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "Specify whether the Secret or its key must be defined";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecValuesFrom" = {

      options = {
        "targetPath" = mkOption {
          description = "";
          type = types.str;
        };
        "valueFrom" = mkOption {
          description = "";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecValuesFromValueFrom");
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecValuesFromValueFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecValuesFromValueFromConfigMapKeyRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecValuesFromValueFromSecretKeyRef"
            )
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecValuesFromValueFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointSpecValuesFromValueFromSecretKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaContactPointStatusConditions")
            )
          );
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaContactPointStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaDashboard" = {

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
          description = "GrafanaDashboardSpec defines the desired state of GrafanaDashboard";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpec");
        };
        "status" = mkOption {
          description = "GrafanaDashboardStatus defines the observed state of GrafanaDashboard";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpec" = {

      options = {
        "allowCrossNamespaceImport" = mkOption {
          description = "Allow the Operator to match this resource with Grafanas outside the current namespace";
          type = (types.nullOr types.bool);
        };
        "configMapRef" = mkOption {
          description = "model from configmap";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecConfigMapRef")
          );
        };
        "contentCacheDuration" = mkOption {
          description = "Cache duration for models fetched from URLs";
          type = (types.nullOr types.str);
        };
        "datasources" = mkOption {
          description = "maps required data sources to existing ones";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecDatasources")
            )
          );
        };
        "envFrom" = mkOption {
          description = "environments variables from secrets or config maps";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvFrom")
            )
          );
        };
        "envs" = mkOption {
          description = "environments variables as a map";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvs" "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "folder" = mkOption {
          description = "folder assignment for dashboard";
          type = (types.nullOr types.str);
        };
        "folderRef" = mkOption {
          description = "Name of a `GrafanaFolder` resource in the same namespace";
          type = (types.nullOr types.str);
        };
        "folderUID" = mkOption {
          description = "UID of the target folder for this dashboard";
          type = (types.nullOr types.str);
        };
        "grafanaCom" = mkOption {
          description = "grafana.com/dashboards";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecGrafanaCom")
          );
        };
        "gzipJson" = mkOption {
          description = "GzipJson the model's JSON compressed with Gzip. Base64-encoded when in YAML.";
          type = (types.nullOr types.str);
        };
        "instanceSelector" = mkOption {
          description = "Selects Grafana instances for import";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecInstanceSelector");
        };
        "json" = mkOption {
          description = "model json";
          type = (types.nullOr types.str);
        };
        "jsonnet" = mkOption {
          description = "Jsonnet";
          type = (types.nullOr types.str);
        };
        "jsonnetLib" = mkOption {
          description = "Jsonnet project build";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecJsonnetLib")
          );
        };
        "oci" = mkOption {
          description = "model from an OCI artifact (e.g. ghcr.io/team/dashboards:v1)";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecOci"));
        };
        "plugins" = mkOption {
          description = "plugins";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecPlugins"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "publicSharing" = mkOption {
          description = "Allows configuration of sharing the dashboard publicly";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecPublicSharing")
          );
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "suspend" = mkOption {
          description = "Suspend pauses synchronizing attempts and tells the operator to ignore changes";
          type = (types.nullOr types.bool);
        };
        "uid" = mkOption {
          description = "Manually specify the uid, overwrites uids already present in the json model.\nCan be any string consisting of alphanumeric characters, - and _ with a maximum length of 40.";
          type = (types.nullOr (types.withMaxLength 40 types.str));
        };
        "url" = mkOption {
          description = "model url";
          type = (types.nullOr types.str);
        };
        "urlAuthorization" = mkOption {
          description = "authorization options for model from url";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecUrlAuthorization")
          );
        };
        "variables" = mkOption {
          description = "overrides the default (current) value of named template variables in the dashboard model.\nVariables that are not present in the model are ignored.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecVariables"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "allowCrossNamespaceImport" = mkOverride 1002 null;
        "configMapRef" = mkOverride 1002 null;
        "contentCacheDuration" = mkOverride 1002 null;
        "datasources" = mkOverride 1002 null;
        "envFrom" = mkOverride 1002 null;
        "envs" = mkOverride 1002 null;
        "folder" = mkOverride 1002 null;
        "folderRef" = mkOverride 1002 null;
        "folderUID" = mkOverride 1002 null;
        "grafanaCom" = mkOverride 1002 null;
        "gzipJson" = mkOverride 1002 null;
        "json" = mkOverride 1002 null;
        "jsonnet" = mkOverride 1002 null;
        "jsonnetLib" = mkOverride 1002 null;
        "oci" = mkOverride 1002 null;
        "plugins" = mkOverride 1002 null;
        "publicSharing" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
        "urlAuthorization" = mkOverride 1002 null;
        "variables" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecConfigMapRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecDatasources" = {

      options = {
        "datasourceName" = mkOption {
          description = "";
          type = types.str;
        };
        "inputName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvFromConfigMapKeyRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a Secret.";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvFromSecretKeyRef")
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvFromSecretKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvs" = {

      options = {
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "value" = mkOption {
          description = "Inline env value";
          type = (types.nullOr types.str);
        };
        "valueFrom" = mkOption {
          description = "Reference on value source, might be the reference on a secret or config map";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvsValueFrom")
          );
        };
      };

      config = {
        "value" = mkOverride 1002 null;
        "valueFrom" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvsValueFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvsValueFromConfigMapKeyRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvsValueFromSecretKeyRef"
            )
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvsValueFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecEnvsValueFromSecretKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecGrafanaCom" = {

      options = {
        "id" = mkOption {
          description = "";
          type = types.int;
        };
        "revision" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "revision" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecInstanceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecInstanceSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecInstanceSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecJsonnetLib" = {

      options = {
        "fileName" = mkOption {
          description = "";
          type = types.str;
        };
        "gzipJsonnetProject" = mkOption {
          description = "";
          type = types.str;
        };
        "jPath" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "jPath" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecOci" = {

      options = {
        "insecurePlainHTTP" = mkOption {
          description = "InsecurePlainHTTP switches the registry connection to plain HTTP (non-TLS) instead of HTTPS.\nIntended for in-cluster or test registries; HTTPS registries with self-signed\ncertificates are not supported. Default false.";
          type = (types.nullOr types.bool);
        };
        "path" = mkOption {
          description = "Path is the path of the file to extract from the artifact.";
          type = (types.withMaxLength 512 (types.withMinLength 1 types.str));
        };
        "pullSecretRef" = mkOption {
          description = "PullSecretRef references a kubernetes.io/dockerconfigjson Secret in the same namespace as the CR.\nIf omitted, anonymous pull is attempted.";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecOciPullSecretRef")
          );
        };
        "reference" = mkOption {
          description = "Reference is the full OCI artifact reference including a tag or digest,\ne.g. \"ghcr.io/team/dashboards:v1.4.7\" or\n\"ghcr.io/team/dashboards@sha256:abc123...\". Prefer a digest for\nreproducible deployments.";
          type = (types.withMaxLength 512 (types.withMinLength 3 types.str));
        };
      };

      config = {
        "insecurePlainHTTP" = mkOverride 1002 null;
        "pullSecretRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecOciPullSecretRef" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecPlugins" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.withMinLength 1 types.str);
        };
        "version" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecPublicSharing" = {

      options = {
        "accessToken" = mkOption {
          description = "Optional. Unique access token. If empty it will generate a new access token per instance.";
          type = (types.nullOr (types.withMaxLength 36 (types.withMinLength 36 types.str)));
        };
        "annotationsEnabled" = mkOption {
          description = "Optional. When set to true, shows annotations. The default value is false.";
          type = (types.nullOr types.bool);
        };
        "enabled" = mkOption {
          description = "Optional. Set to false to disable sharing, the public dashboard is still created. The default value is true.";
          type = (types.nullOr types.bool);
        };
        "timeSelectionEnabled" = mkOption {
          description = "Optional. when set to true, the time picker is enabled in the shared dashboard. The default value is false.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "accessToken" = mkOverride 1002 null;
        "annotationsEnabled" = mkOverride 1002 null;
        "enabled" = mkOverride 1002 null;
        "timeSelectionEnabled" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecUrlAuthorization" = {

      options = {
        "basicAuth" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecUrlAuthorizationBasicAuth"
            )
          );
        };
      };

      config = {
        "basicAuth" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecUrlAuthorizationBasicAuth" = {

      options = {
        "password" = mkOption {
          description = "SecretKeySelector selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecUrlAuthorizationBasicAuthPassword"
            )
          );
        };
        "username" = mkOption {
          description = "SecretKeySelector selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecUrlAuthorizationBasicAuthUsername"
            )
          );
        };
      };

      config = {
        "password" = mkOverride 1002 null;
        "username" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecUrlAuthorizationBasicAuthPassword" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecUrlAuthorizationBasicAuthUsername" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardSpecVariables" = {

      options = {
        "name" = mkOption {
          description = "Name of the template variable to override, matching templating.list[].name in the model.";
          type = (types.withMinLength 1 types.str);
        };
        "value" = mkOption {
          description = "Value is the new default value. For datasource variables this is the datasource UID or\nname; for query, custom, constant and textbox variables it is the selected value.\nMulti-value (multi-select) variables are collapsed to this single value.";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardStatus" = {

      options = {
        "NoMatchingInstances" = mkOption {
          description = "The dashboard instanceSelector can't find matching grafana instances";
          type = (types.nullOr types.bool);
        };
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDashboardStatusConditions")
            )
          );
        };
        "contentCache" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "contentTimestamp" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "contentUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "hash" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
        "publicSharingPath" = mkOption {
          description = "The resulting path where a public sharing config is available";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "NoMatchingInstances" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "contentCache" = mkOverride 1002 null;
        "contentTimestamp" = mkOverride 1002 null;
        "contentUrl" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
        "publicSharingPath" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDashboardStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaDatasource" = {

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
          description = "GrafanaDatasourceSpec defines the desired state of GrafanaDatasource";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpec");
        };
        "status" = mkOption {
          description = "GrafanaDatasourceStatus defines the observed state of GrafanaDatasource";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDatasourceStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpec" = {

      options = {
        "allowCrossNamespaceImport" = mkOption {
          description = "Allow the Operator to match this resource with Grafanas outside the current namespace";
          type = (types.nullOr types.bool);
        };
        "datasource" = mkOption {
          description = "";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecDatasource");
        };
        "instanceSelector" = mkOption {
          description = "Selects Grafana instances for import";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecInstanceSelector");
        };
        "plugins" = mkOption {
          description = "plugins";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecPlugins"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "suspend" = mkOption {
          description = "Suspend pauses synchronizing attempts and tells the operator to ignore changes";
          type = (types.nullOr types.bool);
        };
        "uid" = mkOption {
          description = "The UID, for the datasource, fallback to the deprecated spec.datasource.uid\nand metadata.uid. Can be any string consisting of alphanumeric characters,\n- and _ with a maximum length of 40 +optional";
          type = (types.nullOr (types.withMaxLength 40 types.str));
        };
        "valuesFrom" = mkOption {
          description = "environments variables from secrets or config maps";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecValuesFrom")
            )
          );
        };
      };

      config = {
        "allowCrossNamespaceImport" = mkOverride 1002 null;
        "plugins" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
        "valuesFrom" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecDatasource" = {

      options = {
        "access" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "basicAuth" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "basicAuthUser" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "database" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "editable" = mkOption {
          description = "Whether to enable/disable editing of the datasource in Grafana UI";
          type = (types.nullOr types.bool);
        };
        "isDefault" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "jsonData" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "orgId" = mkOption {
          description = "Deprecated field, it has no effect";
          type = (types.nullOr types.int);
        };
        "secureJsonData" = mkOption {
          description = "";
          type = (types.nullOr types.attrs);
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "Deprecated field, use spec.uid instead";
          type = (types.nullOr types.str);
        };
        "url" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "access" = mkOverride 1002 null;
        "basicAuth" = mkOverride 1002 null;
        "basicAuthUser" = mkOverride 1002 null;
        "database" = mkOverride 1002 null;
        "editable" = mkOverride 1002 null;
        "isDefault" = mkOverride 1002 null;
        "jsonData" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "orgId" = mkOverride 1002 null;
        "secureJsonData" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecInstanceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecInstanceSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecInstanceSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecPlugins" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.withMinLength 1 types.str);
        };
        "version" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecValuesFrom" = {

      options = {
        "targetPath" = mkOption {
          description = "";
          type = types.str;
        };
        "valueFrom" = mkOption {
          description = "";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecValuesFromValueFrom");
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecValuesFromValueFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecValuesFromValueFromConfigMapKeyRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecValuesFromValueFromSecretKeyRef"
            )
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecValuesFromValueFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceSpecValuesFromValueFromSecretKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceStatus" = {

      options = {
        "NoMatchingInstances" = mkOption {
          description = "The datasource instanceSelector can't find matching grafana instances";
          type = (types.nullOr types.bool);
        };
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaDatasourceStatusConditions")
            )
          );
        };
        "hash" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "lastMessage" = mkOption {
          description = "Deprecated: Check status.conditions or operator logs";
          type = (types.nullOr types.str);
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "NoMatchingInstances" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "lastMessage" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaDatasourceStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaFolder" = {

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
          description = "GrafanaFolderSpec defines the desired state of GrafanaFolder";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaFolderSpec");
        };
        "status" = mkOption {
          description = "GrafanaFolderStatus defines the observed state of GrafanaFolder";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaFolderStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaFolderSpec" = {

      options = {
        "allowCrossNamespaceImport" = mkOption {
          description = "Allow the Operator to match this resource with Grafanas outside the current namespace";
          type = (types.nullOr types.bool);
        };
        "instanceSelector" = mkOption {
          description = "Selects Grafana instances for import";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaFolderSpecInstanceSelector");
        };
        "parentFolderRef" = mkOption {
          description = "Reference to an existing GrafanaFolder CR in the same namespace";
          type = (types.nullOr types.str);
        };
        "parentFolderUID" = mkOption {
          description = "UID of the folder in which the current folder should be created";
          type = (types.nullOr types.str);
        };
        "permissions" = mkOption {
          description = "Raw json with folder permissions, potentially exported from Grafana";
          type = (types.nullOr types.str);
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "suspend" = mkOption {
          description = "Suspend pauses synchronizing attempts and tells the operator to ignore changes";
          type = (types.nullOr types.bool);
        };
        "title" = mkOption {
          description = "Display name of the folder in Grafana";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "Manually specify the UID the Folder is created with. Can be any string consisting of alphanumeric characters, - and _ with a maximum length of 40";
          type = (types.nullOr (types.withMaxLength 40 types.str));
        };
      };

      config = {
        "allowCrossNamespaceImport" = mkOverride 1002 null;
        "parentFolderRef" = mkOverride 1002 null;
        "parentFolderUID" = mkOverride 1002 null;
        "permissions" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
        "title" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaFolderSpecInstanceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaFolderSpecInstanceSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaFolderSpecInstanceSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaFolderStatus" = {

      options = {
        "NoMatchingInstances" = mkOption {
          description = "The folder instanceSelector can't find matching grafana instances";
          type = (types.nullOr types.bool);
        };
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaFolderStatusConditions")
            )
          );
        };
        "hash" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "NoMatchingInstances" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaFolderStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanel" = {

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
          description = "GrafanaLibraryPanelSpec defines the desired state of GrafanaLibraryPanel";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpec");
        };
        "status" = mkOption {
          description = "GrafanaLibraryPanelStatus defines the observed state of GrafanaLibraryPanel";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpec" = {

      options = {
        "allowCrossNamespaceImport" = mkOption {
          description = "Allow the Operator to match this resource with Grafanas outside the current namespace";
          type = (types.nullOr types.bool);
        };
        "configMapRef" = mkOption {
          description = "model from configmap";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecConfigMapRef")
          );
        };
        "contentCacheDuration" = mkOption {
          description = "Cache duration for models fetched from URLs";
          type = (types.nullOr types.str);
        };
        "datasources" = mkOption {
          description = "maps required data sources to existing ones";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecDatasources")
            )
          );
        };
        "envFrom" = mkOption {
          description = "environments variables from secrets or config maps";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvFrom")
            )
          );
        };
        "envs" = mkOption {
          description = "environments variables as a map";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvs"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "folderRef" = mkOption {
          description = "Name of a `GrafanaFolder` resource in the same namespace";
          type = (types.nullOr types.str);
        };
        "folderUID" = mkOption {
          description = "UID of the target folder for this dashboard";
          type = (types.nullOr types.str);
        };
        "grafanaCom" = mkOption {
          description = "grafana.com/dashboards";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecGrafanaCom")
          );
        };
        "gzipJson" = mkOption {
          description = "GzipJson the model's JSON compressed with Gzip. Base64-encoded when in YAML.";
          type = (types.nullOr types.str);
        };
        "instanceSelector" = mkOption {
          description = "Selects Grafana instances for import";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecInstanceSelector");
        };
        "json" = mkOption {
          description = "model json";
          type = (types.nullOr types.str);
        };
        "jsonnet" = mkOption {
          description = "Jsonnet";
          type = (types.nullOr types.str);
        };
        "jsonnetLib" = mkOption {
          description = "Jsonnet project build";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecJsonnetLib")
          );
        };
        "oci" = mkOption {
          description = "model from an OCI artifact (e.g. ghcr.io/team/dashboards:v1)";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecOci"));
        };
        "plugins" = mkOption {
          description = "plugins";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecPlugins"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "suspend" = mkOption {
          description = "Suspend pauses synchronizing attempts and tells the operator to ignore changes";
          type = (types.nullOr types.bool);
        };
        "uid" = mkOption {
          description = "Manually specify the uid, overwrites uids already present in the json model.\nCan be any string consisting of alphanumeric characters, - and _ with a maximum length of 40.";
          type = (types.nullOr (types.withMaxLength 40 types.str));
        };
        "url" = mkOption {
          description = "model url";
          type = (types.nullOr types.str);
        };
        "urlAuthorization" = mkOption {
          description = "authorization options for model from url";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecUrlAuthorization")
          );
        };
      };

      config = {
        "allowCrossNamespaceImport" = mkOverride 1002 null;
        "configMapRef" = mkOverride 1002 null;
        "contentCacheDuration" = mkOverride 1002 null;
        "datasources" = mkOverride 1002 null;
        "envFrom" = mkOverride 1002 null;
        "envs" = mkOverride 1002 null;
        "folderRef" = mkOverride 1002 null;
        "folderUID" = mkOverride 1002 null;
        "grafanaCom" = mkOverride 1002 null;
        "gzipJson" = mkOverride 1002 null;
        "json" = mkOverride 1002 null;
        "jsonnet" = mkOverride 1002 null;
        "jsonnetLib" = mkOverride 1002 null;
        "oci" = mkOverride 1002 null;
        "plugins" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
        "url" = mkOverride 1002 null;
        "urlAuthorization" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecConfigMapRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecDatasources" = {

      options = {
        "datasourceName" = mkOption {
          description = "";
          type = types.str;
        };
        "inputName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvFromConfigMapKeyRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvFromSecretKeyRef"
            )
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvFromSecretKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvs" = {

      options = {
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "value" = mkOption {
          description = "Inline env value";
          type = (types.nullOr types.str);
        };
        "valueFrom" = mkOption {
          description = "Reference on value source, might be the reference on a secret or config map";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvsValueFrom")
          );
        };
      };

      config = {
        "value" = mkOverride 1002 null;
        "valueFrom" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvsValueFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvsValueFromConfigMapKeyRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvsValueFromSecretKeyRef"
            )
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvsValueFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecEnvsValueFromSecretKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecGrafanaCom" = {

      options = {
        "id" = mkOption {
          description = "";
          type = types.int;
        };
        "revision" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "revision" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecInstanceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecInstanceSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecInstanceSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecJsonnetLib" = {

      options = {
        "fileName" = mkOption {
          description = "";
          type = types.str;
        };
        "gzipJsonnetProject" = mkOption {
          description = "";
          type = types.str;
        };
        "jPath" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "jPath" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecOci" = {

      options = {
        "insecurePlainHTTP" = mkOption {
          description = "InsecurePlainHTTP switches the registry connection to plain HTTP (non-TLS) instead of HTTPS.\nIntended for in-cluster or test registries; HTTPS registries with self-signed\ncertificates are not supported. Default false.";
          type = (types.nullOr types.bool);
        };
        "path" = mkOption {
          description = "Path is the path of the file to extract from the artifact.";
          type = (types.withMaxLength 512 (types.withMinLength 1 types.str));
        };
        "pullSecretRef" = mkOption {
          description = "PullSecretRef references a kubernetes.io/dockerconfigjson Secret in the same namespace as the CR.\nIf omitted, anonymous pull is attempted.";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecOciPullSecretRef")
          );
        };
        "reference" = mkOption {
          description = "Reference is the full OCI artifact reference including a tag or digest,\ne.g. \"ghcr.io/team/dashboards:v1.4.7\" or\n\"ghcr.io/team/dashboards@sha256:abc123...\". Prefer a digest for\nreproducible deployments.";
          type = (types.withMaxLength 512 (types.withMinLength 3 types.str));
        };
      };

      config = {
        "insecurePlainHTTP" = mkOverride 1002 null;
        "pullSecretRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecOciPullSecretRef" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecPlugins" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.withMinLength 1 types.str);
        };
        "version" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecUrlAuthorization" = {

      options = {
        "basicAuth" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecUrlAuthorizationBasicAuth"
            )
          );
        };
      };

      config = {
        "basicAuth" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecUrlAuthorizationBasicAuth" = {

      options = {
        "password" = mkOption {
          description = "SecretKeySelector selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecUrlAuthorizationBasicAuthPassword"
            )
          );
        };
        "username" = mkOption {
          description = "SecretKeySelector selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecUrlAuthorizationBasicAuthUsername"
            )
          );
        };
      };

      config = {
        "password" = mkOverride 1002 null;
        "username" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecUrlAuthorizationBasicAuthPassword" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelSpecUrlAuthorizationBasicAuthUsername" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelStatusConditions")
            )
          );
        };
        "contentCache" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "contentTimestamp" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "contentUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "hash" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "contentCache" = mkOverride 1002 null;
        "contentTimestamp" = mkOverride 1002 null;
        "contentUrl" = mkOverride 1002 null;
        "hash" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaLibraryPanelStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaManifest" = {

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
          description = "GrafanaManifestSpec defines the desired state of a GrafanaManifest";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestSpec");
        };
        "status" = mkOption {
          description = "GrafanaManifestStatus defines the observed state of GrafanaManifest";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpec" = {

      options = {
        "allowCrossNamespaceImport" = mkOption {
          description = "Allow the Operator to match this resource with Grafanas outside the current namespace";
          type = (types.nullOr types.bool);
        };
        "instanceSelector" = mkOption {
          description = "Selects Grafana instances for import";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestSpecInstanceSelector");
        };
        "patch" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatch"));
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "suspend" = mkOption {
          description = "Suspend pauses synchronizing attempts and tells the operator to ignore changes";
          type = (types.nullOr types.bool);
        };
        "template" = mkOption {
          description = "";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestSpecTemplate");
        };
      };

      config = {
        "allowCrossNamespaceImport" = mkOverride 1002 null;
        "patch" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpecInstanceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestSpecInstanceSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpecInstanceSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatch" = {

      options = {
        "env" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatchEnv"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "scripts" = mkOption {
          description = "";
          type = (types.listOf types.str);
        };
      };

      config = {
        "env" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatchEnv" = {

      options = {
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "valueFrom" = mkOption {
          description = "";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatchEnvValueFrom");
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatchEnvValueFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatchEnvValueFromConfigMapKeyRef"
            )
          );
        };
        "grafanaRef" = mkOption {
          description = "ObjectFieldSelector selects an APIVersioned field of an object.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatchEnvValueFromGrafanaRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a Secret.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatchEnvValueFromSecretKeyRef"
            )
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "grafanaRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatchEnvValueFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatchEnvValueFromGrafanaRef" = {

      options = {
        "apiVersion" = mkOption {
          description = "Version of the schema the FieldPath is written in terms of, defaults to \"v1\".";
          type = (types.nullOr types.str);
        };
        "fieldPath" = mkOption {
          description = "Path of the field to select in the specified API version.";
          type = types.str;
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpecPatchEnvValueFromSecretKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpecTemplate" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.";
          type = types.str;
        };
        "metadata" = mkOption {
          description = "RequiredObjectMeta contains only a [subset of the fields included in k8s.io/apimachinery/pkg/apis/meta/v1.ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#objectmeta-v1-meta).\nIt requires `name` to be set";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestSpecTemplateMetadata");
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr types.unspecified);
        };
      };

      config = {
        "spec" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestSpecTemplateMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "namespace" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaManifestStatusConditions")
            )
          );
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaManifestStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaMuteTiming" = {

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
          description = "GrafanaMuteTimingSpec defines the desired state of GrafanaMuteTiming";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaMuteTimingSpec");
        };
        "status" = mkOption {
          description = "The most recent observed state of a Grafana resource";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaMuteTimingStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaMuteTimingSpec" = {

      options = {
        "allowCrossNamespaceImport" = mkOption {
          description = "Allow the Operator to match this resource with Grafanas outside the current namespace";
          type = (types.nullOr types.bool);
        };
        "editable" = mkOption {
          description = "Whether to enable or disable editing of the mute timing in Grafana UI";
          type = (types.nullOr types.bool);
        };
        "instanceSelector" = mkOption {
          description = "Selects Grafana instances for import";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaMuteTimingSpecInstanceSelector");
        };
        "name" = mkOption {
          description = "A unique name for the mute timing";
          type = types.str;
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "suspend" = mkOption {
          description = "Suspend pauses synchronizing attempts and tells the operator to ignore changes";
          type = (types.nullOr types.bool);
        };
        "time_intervals" = mkOption {
          description = "Time intervals for muting";
          type = (
            types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaMuteTimingSpecTime_intervals")
          );
        };
      };

      config = {
        "allowCrossNamespaceImport" = mkOverride 1002 null;
        "editable" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaMuteTimingSpecInstanceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaMuteTimingSpecInstanceSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaMuteTimingSpecInstanceSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaMuteTimingSpecTime_intervals" = {

      options = {
        "days_of_month" = mkOption {
          description = "The date 1-31 of a month. Negative values can also be used to represent days that begin at the end of the month.\nFor example: -1 for the last day of the month.";
          type = (types.nullOr (types.listOf types.str));
        };
        "location" = mkOption {
          description = "Depending on the location, the time range is displayed in local time.";
          type = (types.nullOr types.str);
        };
        "months" = mkOption {
          description = "The months of the year in either numerical or the full calendar month.\nFor example: 1, may.";
          type = (types.nullOr (types.listOf types.str));
        };
        "times" = mkOption {
          description = "The time inclusive of the start and exclusive of the end time (in UTC if no location has been selected, otherwise local time).";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaMuteTimingSpecTime_intervalsTimes"
              )
            )
          );
        };
        "weekdays" = mkOption {
          description = "The day or range of days of the week.\nFor example: monday, thursday";
          type = (types.nullOr (types.listOf types.str));
        };
        "years" = mkOption {
          description = "The year or years for the interval.\nFor example: 2021";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "days_of_month" = mkOverride 1002 null;
        "location" = mkOverride 1002 null;
        "months" = mkOverride 1002 null;
        "times" = mkOverride 1002 null;
        "weekdays" = mkOverride 1002 null;
        "years" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaMuteTimingSpecTime_intervalsTimes" = {

      options = {
        "end_time" = mkOption {
          description = "end time";
          type = types.str;
        };
        "start_time" = mkOption {
          description = "start time";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaMuteTimingStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaMuteTimingStatusConditions")
            )
          );
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaMuteTimingStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicy" = {

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
          description = "GrafanaNotificationPolicySpec defines the desired state of GrafanaNotificationPolicy";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpec");
        };
        "status" = mkOption {
          description = "GrafanaNotificationPolicyStatus defines the observed state of GrafanaNotificationPolicy";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyStatus")
          );
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRoute" = {

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
          description = "GrafanaNotificationPolicyRouteSpec defines the desired state of GrafanaNotificationPolicyRoute";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteSpec");
        };
        "status" = mkOption {
          description = "The most recent observed state of a Grafana resource";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteStatus")
          );
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteSpec" = {

      options = {
        "active_time_intervals" = mkOption {
          description = "active time intervals";
          type = (types.nullOr (types.listOf types.str));
        };
        "continue" = mkOption {
          description = "continue";
          type = (types.nullOr types.bool);
        };
        "group_by" = mkOption {
          description = "group by";
          type = (types.nullOr (types.listOf types.str));
        };
        "group_interval" = mkOption {
          description = "group interval";
          type = (types.nullOr types.str);
        };
        "group_wait" = mkOption {
          description = "group wait";
          type = (types.nullOr types.str);
        };
        "match_re" = mkOption {
          description = "match re";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "matchers" = mkOption {
          description = "matchers";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteSpecMatchers"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "mute_time_intervals" = mkOption {
          description = "mute time intervals";
          type = (types.nullOr (types.listOf types.str));
        };
        "object_matchers" = mkOption {
          description = "object matchers";
          type = (types.nullOr (types.listOf (types.listOf types.str)));
        };
        "provenance" = mkOption {
          description = "Deprecated: Does nothing";
          type = (types.nullOr types.str);
        };
        "receiver" = mkOption {
          description = "receiver";
          type = (types.withMinLength 1 types.str);
        };
        "repeat_interval" = mkOption {
          description = "repeat interval";
          type = (types.nullOr types.str);
        };
        "routeSelector" = mkOption {
          description = "selects GrafanaNotificationPolicyRoutes to merge in when specified\nmutually exclusive with Routes";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteSpecRouteSelector"
            )
          );
        };
        "routes" = mkOption {
          description = "routes, mutually exclusive with RouteSelector";
          type = (types.nullOr types.unspecified);
        };
      };

      config = {
        "active_time_intervals" = mkOverride 1002 null;
        "continue" = mkOverride 1002 null;
        "group_by" = mkOverride 1002 null;
        "group_interval" = mkOverride 1002 null;
        "group_wait" = mkOverride 1002 null;
        "match_re" = mkOverride 1002 null;
        "matchers" = mkOverride 1002 null;
        "mute_time_intervals" = mkOverride 1002 null;
        "object_matchers" = mkOverride 1002 null;
        "provenance" = mkOverride 1002 null;
        "repeat_interval" = mkOverride 1002 null;
        "routeSelector" = mkOverride 1002 null;
        "routes" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteSpecMatchers" = {

      options = {
        "isEqual" = mkOption {
          description = "Deprecated: Does nothing and is not exported by Grafana";
          type = (types.nullOr types.bool);
        };
        "isRegex" = mkOption {
          description = "Deprecated: Does nothing and is not exported by Grafana";
          type = types.bool;
        };
        "name" = mkOption {
          description = "name";
          type = (types.nullOr types.str);
        };
        "value" = mkOption {
          description = "value";
          type = types.str;
        };
      };

      config = {
        "isEqual" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteSpecRouteSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteSpecRouteSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteSpecRouteSelectorMatchExpressions" =
      {

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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteStatusConditions"
              )
            )
          );
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRouteStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpec" = {

      options = {
        "allowCrossNamespaceImport" = mkOption {
          description = "Allow the Operator to match this resource with Grafanas outside the current namespace";
          type = (types.nullOr types.bool);
        };
        "editable" = mkOption {
          description = "Whether to enable or disable editing of the notification policy in Grafana UI";
          type = (types.nullOr types.bool);
        };
        "instanceSelector" = mkOption {
          description = "Selects Grafana instances for import";
          type = (
            submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecInstanceSelector"
          );
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "route" = mkOption {
          description = "Routes for alerts to match against";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecRoute");
        };
        "suspend" = mkOption {
          description = "Suspend pauses synchronizing attempts and tells the operator to ignore changes";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "allowCrossNamespaceImport" = mkOverride 1002 null;
        "editable" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecInstanceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecInstanceSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecInstanceSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecRoute" = {

      options = {
        "active_time_intervals" = mkOption {
          description = "Deprecated: Never worked on the top level route node";
          type = (types.nullOr (types.listOf types.str));
        };
        "continue" = mkOption {
          description = "Deprecated: Never worked on the top level route node";
          type = (types.nullOr types.bool);
        };
        "group_by" = mkOption {
          description = "group by";
          type = (types.nullOr (types.listOf types.str));
        };
        "group_interval" = mkOption {
          description = "group interval";
          type = (types.nullOr types.str);
        };
        "group_wait" = mkOption {
          description = "group wait";
          type = (types.nullOr types.str);
        };
        "match_re" = mkOption {
          description = "Deprecated: Never worked on the top level route node";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "matchers" = mkOption {
          description = "Deprecated: Never worked on the top level route node";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecRouteMatchers"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "mute_time_intervals" = mkOption {
          description = "Deprecated: Never worked on the top level route node";
          type = (types.nullOr (types.listOf types.str));
        };
        "object_matchers" = mkOption {
          description = "Deprecated: Never worked on the top level route node";
          type = (types.nullOr (types.listOf (types.listOf types.str)));
        };
        "provenance" = mkOption {
          description = "Deprecated: Does nothing";
          type = (types.nullOr types.str);
        };
        "receiver" = mkOption {
          description = "receiver";
          type = (types.withMinLength 1 types.str);
        };
        "repeat_interval" = mkOption {
          description = "repeat interval";
          type = (types.nullOr types.str);
        };
        "routeSelector" = mkOption {
          description = "selects GrafanaNotificationPolicyRoutes to merge in when specified\nmutually exclusive with Routes";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecRouteRouteSelector"
            )
          );
        };
        "routes" = mkOption {
          description = "routes, mutually exclusive with RouteSelector";
          type = (types.nullOr types.unspecified);
        };
      };

      config = {
        "active_time_intervals" = mkOverride 1002 null;
        "continue" = mkOverride 1002 null;
        "group_by" = mkOverride 1002 null;
        "group_interval" = mkOverride 1002 null;
        "group_wait" = mkOverride 1002 null;
        "match_re" = mkOverride 1002 null;
        "matchers" = mkOverride 1002 null;
        "mute_time_intervals" = mkOverride 1002 null;
        "object_matchers" = mkOverride 1002 null;
        "provenance" = mkOverride 1002 null;
        "repeat_interval" = mkOverride 1002 null;
        "routeSelector" = mkOverride 1002 null;
        "routes" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecRouteMatchers" = {

      options = {
        "isEqual" = mkOption {
          description = "Deprecated: Does nothing and is not exported by Grafana";
          type = (types.nullOr types.bool);
        };
        "isRegex" = mkOption {
          description = "Deprecated: Does nothing and is not exported by Grafana";
          type = types.bool;
        };
        "name" = mkOption {
          description = "name";
          type = (types.nullOr types.str);
        };
        "value" = mkOption {
          description = "value";
          type = types.str;
        };
      };

      config = {
        "isEqual" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecRouteRouteSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecRouteRouteSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicySpecRouteRouteSelectorMatchExpressions" =
      {

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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyStatusConditions"
              )
            )
          );
        };
        "discoveredRoutes" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "discoveredRoutes" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplate" = {

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
          description = "GrafanaNotificationTemplateSpec defines the desired state of GrafanaNotificationTemplate";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplateSpec");
        };
        "status" = mkOption {
          description = "The most recent observed state of a Grafana resource";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplateStatus")
          );
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplateSpec" = {

      options = {
        "allowCrossNamespaceImport" = mkOption {
          description = "Allow the Operator to match this resource with Grafanas outside the current namespace";
          type = (types.nullOr types.bool);
        };
        "editable" = mkOption {
          description = "Whether to enable or disable editing of the notification template in Grafana UI";
          type = (types.nullOr types.bool);
        };
        "instanceSelector" = mkOption {
          description = "Selects Grafana instances for import";
          type = (
            submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplateSpecInstanceSelector"
          );
        };
        "name" = mkOption {
          description = "Template name";
          type = types.str;
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "suspend" = mkOption {
          description = "Suspend pauses synchronizing attempts and tells the operator to ignore changes";
          type = (types.nullOr types.bool);
        };
        "template" = mkOption {
          description = "Template content";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "allowCrossNamespaceImport" = mkOverride 1002 null;
        "editable" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
        "template" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplateSpecInstanceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplateSpecInstanceSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplateSpecInstanceSelectorMatchExpressions" =
      {

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
    "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplateStatus" = {

      options = {
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplateStatusConditions"
              )
            )
          );
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplateStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaServiceAccount" = {

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
          description = "GrafanaServiceAccountSpec defines the desired state of a GrafanaServiceAccount.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaServiceAccountSpec"));
        };
        "status" = mkOption {
          description = "GrafanaServiceAccountStatus defines the observed state of a GrafanaServiceAccount";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaServiceAccountStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaServiceAccountSpec" = {

      options = {
        "instanceName" = mkOption {
          description = "Name of the Grafana instance to create the service account for";
          type = (types.withMinLength 1 types.str);
        };
        "isDisabled" = mkOption {
          description = "Whether the service account is disabled";
          type = (types.nullOr types.bool);
        };
        "name" = mkOption {
          description = "Name of the service account in Grafana";
          type = (types.nullOr (types.withMinLength 1 types.str));
        };
        "resyncPeriod" = mkOption {
          description = "How often the resource is synced, defaults to 10m0s if not set";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "Role of the service account (Viewer, Editor, Admin)";
          type = (
            types.enum [
              "Viewer"
              "Editor"
              "Admin"
            ]
          );
        };
        "suspend" = mkOption {
          description = "Suspend pauses reconciliation of the service account";
          type = (types.nullOr types.bool);
        };
        "tokens" = mkOption {
          description = "Tokens to create for the service account";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "grafana.integreatly.org.v1beta1.GrafanaServiceAccountSpecTokens"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "isDisabled" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "resyncPeriod" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
        "tokens" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaServiceAccountSpecTokens" = {

      options = {
        "expires" = mkOption {
          description = "Expiration date of the token. If not set, the token never expires";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the token";
          type = (types.withMinLength 1 types.str);
        };
        "secretName" = mkOption {
          description = "Name of the secret to store the token. If not set, a name will be generated";
          type = (types.nullOr (types.withMinLength 1 types.str));
        };
      };

      config = {
        "expires" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaServiceAccountStatus" = {

      options = {
        "account" = mkOption {
          description = "Info contains the Grafana service account information";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaServiceAccountStatusAccount")
          );
        };
        "conditions" = mkOption {
          description = "Results when synchronizing resource with Grafana instances";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaServiceAccountStatusConditions")
            )
          );
        };
        "lastResync" = mkOption {
          description = "Last time the resource was synchronized with Grafana instances";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "account" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "lastResync" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaServiceAccountStatusAccount" = {

      options = {
        "id" = mkOption {
          description = "ID of the service account in Grafana";
          type = types.int;
        };
        "isDisabled" = mkOption {
          description = "IsDisabled indicates if the service account is disabled";
          type = types.bool;
        };
        "login" = mkOption {
          description = "";
          type = types.str;
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "role" = mkOption {
          description = "Role is the Grafana role for the service account (Viewer, Editor, Admin)";
          type = types.str;
        };
        "tokens" = mkOption {
          description = "Information about tokens";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaServiceAccountStatusAccountTokens"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "tokens" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaServiceAccountStatusAccountTokens" = {

      options = {
        "expires" = mkOption {
          description = "Expiration time of the token\nN.B. There's possible discrepancy with the expiration time in spec\nIt happens because Grafana API accepts TTL in seconds then calculates the expiration time against the current time";
          type = (types.nullOr types.str);
        };
        "id" = mkOption {
          description = "ID of the token in Grafana";
          type = types.int;
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "secret" = mkOption {
          description = "Name of the secret containing the token";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaServiceAccountStatusAccountTokensSecret"
            )
          );
        };
      };

      config = {
        "expires" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaServiceAccountStatusAccountTokensSecret" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaServiceAccountStatusConditions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaSpec" = {

      options = {
        "client" = mkOption {
          description = "Client defines how the grafana-operator talks to the grafana instance.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecClient"));
        };
        "config" = mkOption {
          description = "Config defines how your grafana ini file should looks like.";
          type = (types.nullOr (types.attrsOf types.attrs));
        };
        "deployment" = mkOption {
          description = "Deployment sets how the deployment object should look like with your grafana instance, contains a number of defaults.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeployment"));
        };
        "disableDefaultAdminSecret" = mkOption {
          description = "DisableDefaultAdminSecret prevents operator from creating default admin-credentials secret";
          type = (types.nullOr types.bool);
        };
        "disableDefaultSecurityContext" = mkOption {
          description = "DisableDefaultSecurityContext prevents the operator from populating securityContext on deployments";
          type = (
            types.nullOr (
              types.enum [
                "Pod"
                "Container"
                "All"
              ]
            )
          );
        };
        "external" = mkOption {
          description = "External enables you to configure external grafana instances that is not managed by the operator.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecExternal"));
        };
        "httpRoute" = mkOption {
          description = "HTTPRoute customizes the GatewayAPI HTTPRoute Object. It will not be created if this is not set";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRoute"));
        };
        "ingress" = mkOption {
          description = "Ingress sets how the ingress object should look like with your grafana instance.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngress"));
        };
        "jsonnet" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecJsonnet"));
        };
        "persistentVolumeClaim" = mkOption {
          description = "PersistentVolumeClaim creates a PVC if you need to attach one to your grafana instance.";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaim")
          );
        };
        "preferences" = mkOption {
          description = "Preferences holds the Grafana Preferences settings";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecPreferences"));
        };
        "route" = mkOption {
          description = "Route sets how the ingress object should look like with your grafana instance, this only works in Openshift.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecRoute"));
        };
        "service" = mkOption {
          description = "Service sets how the service object should look like with your grafana instance, contains a number of defaults.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecService"));
        };
        "serviceAccount" = mkOption {
          description = "ServiceAccount sets how the ServiceAccount object should look like with your grafana instance, contains a number of defaults.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecServiceAccount"));
        };
        "suspend" = mkOption {
          description = "Suspend pauses reconciliation of owned resources like deployments, Services, Etc. upon changes";
          type = (types.nullOr types.bool);
        };
        "version" = mkOption {
          description = "Version sets the tag of the default image: docker.io/grafana/grafana.\nAllows full image refs with/without sha256checksum: \"registry/repo/image:tag@sha\"\ndefault: 13.1.3";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "client" = mkOverride 1002 null;
        "config" = mkOverride 1002 null;
        "deployment" = mkOverride 1002 null;
        "disableDefaultAdminSecret" = mkOverride 1002 null;
        "disableDefaultSecurityContext" = mkOverride 1002 null;
        "external" = mkOverride 1002 null;
        "httpRoute" = mkOverride 1002 null;
        "ingress" = mkOverride 1002 null;
        "jsonnet" = mkOverride 1002 null;
        "persistentVolumeClaim" = mkOverride 1002 null;
        "preferences" = mkOverride 1002 null;
        "route" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "suspend" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecClient" = {

      options = {
        "headers" = mkOption {
          description = "Custom HTTP headers to use when interacting with this Grafana.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "preferIngress" = mkOption {
          description = "If the operator should send it's request through the grafana instances ingress object instead of through the service.";
          type = (types.nullOr types.bool);
        };
        "timeout" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "tls" = mkOption {
          description = "TLS Configuration used to talk with the grafana instance.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecClientTls"));
        };
        "useKubeAuth" = mkOption {
          description = "Use Kubernetes Serviceaccount as authentication\nRequires configuring [auth.jwt] in the instance";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "headers" = mkOverride 1002 null;
        "preferIngress" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "useKubeAuth" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecClientTls" = {

      options = {
        "certSecretRef" = mkOption {
          description = "Use a secret as a reference to give TLS Certificate information";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecClientTlsCertSecretRef")
          );
        };
        "insecureSkipVerify" = mkOption {
          description = "Disable the CA check of the server";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "certSecretRef" = mkOverride 1002 null;
        "insecureSkipVerify" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecClientTlsCertSecretRef" = {

      options = {
        "name" = mkOption {
          description = "name is unique within a namespace to reference a secret resource.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "namespace defines the space within which the secret name must be unique.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeployment" = {

      options = {
        "metadata" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentMetadata"));
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpec"));
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpec" = {

      options = {
        "minReadySeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "paused" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "progressDeadlineSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "replicas" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "revisionHistoryLimit" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "selector" = mkOption {
          description = "";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecSelector")
          );
        };
        "strategy" = mkOption {
          description = "";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecStrategy")
          );
        };
        "template" = mkOption {
          description = "";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplate")
          );
        };
      };

      config = {
        "minReadySeconds" = mkOverride 1002 null;
        "paused" = mkOverride 1002 null;
        "progressDeadlineSeconds" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "revisionHistoryLimit" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "strategy" = mkOverride 1002 null;
        "template" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecSelectorMatchExpressions"
              )
            )
          );
        };
        "matchLabels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "matchExpressions" = mkOverride 1002 null;
        "matchLabels" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecSelectorMatchExpressions" = {

      options = {
        "key" = mkOption {
          description = "";
          type = types.str;
        };
        "operator" = mkOption {
          description = "";
          type = types.str;
        };
        "values" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "values" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecStrategy" = {

      options = {
        "rollingUpdate" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecStrategyRollingUpdate"
            )
          );
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "rollingUpdate" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecStrategyRollingUpdate" = {

      options = {
        "maxSurge" = mkOption {
          description = "";
          type = (types.nullOr (types.either types.int types.str));
        };
        "maxUnavailable" = mkOption {
          description = "";
          type = (types.nullOr (types.either types.int types.str));
        };
      };

      config = {
        "maxSurge" = mkOverride 1002 null;
        "maxUnavailable" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplate" = {

      options = {
        "metadata" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateMetadata"
            )
          );
        };
        "spec" = mkOption {
          description = "";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpec")
          );
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpec" = {

      options = {
        "activeDeadlineSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "affinity" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinity"
            )
          );
        };
        "automountServiceAccountToken" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "containers" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainers"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "dnsConfig" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecDnsConfig"
            )
          );
        };
        "dnsPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "enableServiceLinks" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "ephemeralContainers" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainers"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "hostAliases" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecHostAliases"
              )
            )
          );
        };
        "hostIPC" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "hostNetwork" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "hostPID" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "hostUsers" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "hostname" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "imagePullSecrets" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecImagePullSecrets"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "initContainers" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainers"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "nodeName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "nodeSelector" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "os" = mkOption {
          description = "";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecOs")
          );
        };
        "overhead" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "preemptionPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "priority" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "priorityClassName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "readinessGates" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecReadinessGates"
              )
            )
          );
        };
        "restartPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "runtimeClassName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "schedulerName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "securityContext" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContext"
            )
          );
        };
        "serviceAccount" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "serviceAccountName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "setHostnameAsFQDN" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "shareProcessNamespace" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "subdomain" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "terminationGracePeriodSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "tolerations" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecTolerations"
              )
            )
          );
        };
        "topologySpreadConstraints" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecTopologySpreadConstraints"
              )
            )
          );
        };
        "volumes" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumes"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "activeDeadlineSeconds" = mkOverride 1002 null;
        "affinity" = mkOverride 1002 null;
        "automountServiceAccountToken" = mkOverride 1002 null;
        "containers" = mkOverride 1002 null;
        "dnsConfig" = mkOverride 1002 null;
        "dnsPolicy" = mkOverride 1002 null;
        "enableServiceLinks" = mkOverride 1002 null;
        "ephemeralContainers" = mkOverride 1002 null;
        "hostAliases" = mkOverride 1002 null;
        "hostIPC" = mkOverride 1002 null;
        "hostNetwork" = mkOverride 1002 null;
        "hostPID" = mkOverride 1002 null;
        "hostUsers" = mkOverride 1002 null;
        "hostname" = mkOverride 1002 null;
        "imagePullSecrets" = mkOverride 1002 null;
        "initContainers" = mkOverride 1002 null;
        "nodeName" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "os" = mkOverride 1002 null;
        "overhead" = mkOverride 1002 null;
        "preemptionPolicy" = mkOverride 1002 null;
        "priority" = mkOverride 1002 null;
        "priorityClassName" = mkOverride 1002 null;
        "readinessGates" = mkOverride 1002 null;
        "restartPolicy" = mkOverride 1002 null;
        "runtimeClassName" = mkOverride 1002 null;
        "schedulerName" = mkOverride 1002 null;
        "securityContext" = mkOverride 1002 null;
        "serviceAccount" = mkOverride 1002 null;
        "serviceAccountName" = mkOverride 1002 null;
        "setHostnameAsFQDN" = mkOverride 1002 null;
        "shareProcessNamespace" = mkOverride 1002 null;
        "subdomain" = mkOverride 1002 null;
        "terminationGracePeriodSeconds" = mkOverride 1002 null;
        "tolerations" = mkOverride 1002 null;
        "topologySpreadConstraints" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinity"
            )
          );
        };
        "podAffinity" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinity"
            )
          );
        };
        "podAntiAffinity" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinity"
            )
          );
        };
      };

      config = {
        "nodeAffinity" = mkOverride 1002 null;
        "podAffinity" = mkOverride 1002 null;
        "podAntiAffinity" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "";
            type = (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "";
            type = types.int;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "";
            type = (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
                )
              )
            );
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchFields" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "";
            type = (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "";
            type = types.int;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "";
            type = (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "";
            type = types.int;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "matchLabelKeys" = mkOverride 1002 null;
          "mismatchLabelKeys" = mkOverride 1002 null;
          "namespaceSelector" = mkOverride 1002 null;
          "namespaces" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainers" = {

      options = {
        "args" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "command" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "env" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnv"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "envFrom" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvFrom"
              )
            )
          );
        };
        "image" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "imagePullPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "lifecycle" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecycle"
            )
          );
        };
        "livenessProbe" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbe"
            )
          );
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "ports" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersPorts"
                "name"
                [
                  "containerPort"
                  "protocol"
                ]
            )
          );
          apply = attrsToList;
        };
        "readinessProbe" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbe"
            )
          );
        };
        "resizePolicy" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersResizePolicy"
              )
            )
          );
        };
        "resources" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersResources"
            )
          );
        };
        "restartPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "restartPolicyRules" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersRestartPolicyRules"
              )
            )
          );
        };
        "securityContext" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContext"
            )
          );
        };
        "startupProbe" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbe"
            )
          );
        };
        "stdin" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "stdinOnce" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "terminationMessagePath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "terminationMessagePolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "tty" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "volumeDevices" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersVolumeDevices"
                "name"
                [ "devicePath" ]
            )
          );
          apply = attrsToList;
        };
        "volumeMounts" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersVolumeMounts"
                "name"
                [ "mountPath" ]
            )
          );
          apply = attrsToList;
        };
        "workingDir" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "args" = mkOverride 1002 null;
        "command" = mkOverride 1002 null;
        "env" = mkOverride 1002 null;
        "envFrom" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "imagePullPolicy" = mkOverride 1002 null;
        "lifecycle" = mkOverride 1002 null;
        "livenessProbe" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
        "readinessProbe" = mkOverride 1002 null;
        "resizePolicy" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "restartPolicy" = mkOverride 1002 null;
        "restartPolicyRules" = mkOverride 1002 null;
        "securityContext" = mkOverride 1002 null;
        "startupProbe" = mkOverride 1002 null;
        "stdin" = mkOverride 1002 null;
        "stdinOnce" = mkOverride 1002 null;
        "terminationMessagePath" = mkOverride 1002 null;
        "terminationMessagePolicy" = mkOverride 1002 null;
        "tty" = mkOverride 1002 null;
        "volumeDevices" = mkOverride 1002 null;
        "volumeMounts" = mkOverride 1002 null;
        "workingDir" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnv" = {

      options = {
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "value" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "valueFrom" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFrom"
            )
          );
        };
      };

      config = {
        "value" = mkOverride 1002 null;
        "valueFrom" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvFrom" = {

      options = {
        "configMapRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvFromConfigMapRef"
            )
          );
        };
        "prefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvFromSecretRef"
            )
          );
        };
      };

      config = {
        "configMapRef" = mkOverride 1002 null;
        "prefix" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvFromConfigMapRef" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvFromSecretRef" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFromConfigMapKeyRef"
            )
          );
        };
        "fieldRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFromFieldRef"
            )
          );
        };
        "fileKeyRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFromFileKeyRef"
            )
          );
        };
        "resourceFieldRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFromResourceFieldRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFromSecretKeyRef"
            )
          );
        };
      };

      config = {
        "configMapKeyRef" = mkOverride 1002 null;
        "fieldRef" = mkOverride 1002 null;
        "fileKeyRef" = mkOverride 1002 null;
        "resourceFieldRef" = mkOverride 1002 null;
        "secretKeyRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFromConfigMapKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFromFieldRef" =
      {

        options = {
          "apiVersion" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "fieldPath" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "apiVersion" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFromFileKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "path" = mkOption {
            description = "";
            type = types.str;
          };
          "volumeName" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFromResourceFieldRef" =
      {

        options = {
          "containerName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "divisor" = mkOption {
            description = "";
            type = (types.nullOr (types.either types.int types.str));
          };
          "resource" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "containerName" = mkOverride 1002 null;
          "divisor" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersEnvValueFromSecretKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecycle" = {

      options = {
        "postStart" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStart"
            )
          );
        };
        "preStop" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStop"
            )
          );
        };
        "stopSignal" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "postStart" = mkOverride 1002 null;
        "preStop" = mkOverride 1002 null;
        "stopSignal" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStart" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStartExec"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStartHttpGet"
              )
            );
          };
          "sleep" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStartSleep"
              )
            );
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStartTcpSocket"
              )
            );
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "sleep" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStartExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStartHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStartHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStartHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStartSleep" =
      {

        options = {
          "seconds" = mkOption {
            description = "";
            type = types.int;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePostStartTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStop" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStopExec"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStopHttpGet"
              )
            );
          };
          "sleep" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStopSleep"
              )
            );
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStopTcpSocket"
              )
            );
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "sleep" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStopExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStopHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStopHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStopHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStopSleep" =
      {

        options = {
          "seconds" = mkOption {
            description = "";
            type = types.int;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLifecyclePreStopTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbe" = {

      options = {
        "exec" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbeExec"
            )
          );
        };
        "failureThreshold" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "grpc" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbeGrpc"
            )
          );
        };
        "httpGet" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbeHttpGet"
            )
          );
        };
        "initialDelaySeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "periodSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "successThreshold" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "tcpSocket" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbeTcpSocket"
            )
          );
        };
        "terminationGracePeriodSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "timeoutSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "exec" = mkOverride 1002 null;
        "failureThreshold" = mkOverride 1002 null;
        "grpc" = mkOverride 1002 null;
        "httpGet" = mkOverride 1002 null;
        "initialDelaySeconds" = mkOverride 1002 null;
        "periodSeconds" = mkOverride 1002 null;
        "successThreshold" = mkOverride 1002 null;
        "tcpSocket" = mkOverride 1002 null;
        "terminationGracePeriodSeconds" = mkOverride 1002 null;
        "timeoutSeconds" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbeExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbeGrpc" =
      {

        options = {
          "port" = mkOption {
            description = "";
            type = types.int;
          };
          "service" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "service" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbeHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbeHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbeHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersLivenessProbeTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersPorts" = {

      options = {
        "containerPort" = mkOption {
          description = "";
          type = types.int;
        };
        "hostIP" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "hostPort" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "protocol" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "hostIP" = mkOverride 1002 null;
        "hostPort" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "protocol" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbe" = {

      options = {
        "exec" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbeExec"
            )
          );
        };
        "failureThreshold" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "grpc" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbeGrpc"
            )
          );
        };
        "httpGet" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbeHttpGet"
            )
          );
        };
        "initialDelaySeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "periodSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "successThreshold" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "tcpSocket" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbeTcpSocket"
            )
          );
        };
        "terminationGracePeriodSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "timeoutSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "exec" = mkOverride 1002 null;
        "failureThreshold" = mkOverride 1002 null;
        "grpc" = mkOverride 1002 null;
        "httpGet" = mkOverride 1002 null;
        "initialDelaySeconds" = mkOverride 1002 null;
        "periodSeconds" = mkOverride 1002 null;
        "successThreshold" = mkOverride 1002 null;
        "tcpSocket" = mkOverride 1002 null;
        "terminationGracePeriodSeconds" = mkOverride 1002 null;
        "timeoutSeconds" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbeExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbeGrpc" =
      {

        options = {
          "port" = mkOption {
            description = "";
            type = types.int;
          };
          "service" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "service" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbeHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbeHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbeHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersReadinessProbeTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersResizePolicy" = {

      options = {
        "resourceName" = mkOption {
          description = "";
          type = types.str;
        };
        "restartPolicy" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersResources" = {

      options = {
        "claims" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersResourcesClaims"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "limits" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "requests" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
      };

      config = {
        "claims" = mkOverride 1002 null;
        "limits" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersResourcesClaims" = {

      options = {
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "request" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "request" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersRestartPolicyRules" =
      {

        options = {
          "action" = mkOption {
            description = "";
            type = types.str;
          };
          "exitCodes" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersRestartPolicyRulesExitCodes"
              )
            );
          };
        };

        config = {
          "exitCodes" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersRestartPolicyRulesExitCodes" =
      {

        options = {
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.int));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContext" = {

      options = {
        "allowPrivilegeEscalation" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "appArmorProfile" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContextAppArmorProfile"
            )
          );
        };
        "capabilities" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContextCapabilities"
            )
          );
        };
        "privileged" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "procMount" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "readOnlyRootFilesystem" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "runAsGroup" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "seLinuxOptions" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContextSeLinuxOptions"
            )
          );
        };
        "seccompProfile" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContextSeccompProfile"
            )
          );
        };
        "windowsOptions" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContextWindowsOptions"
            )
          );
        };
      };

      config = {
        "allowPrivilegeEscalation" = mkOverride 1002 null;
        "appArmorProfile" = mkOverride 1002 null;
        "capabilities" = mkOverride 1002 null;
        "privileged" = mkOverride 1002 null;
        "procMount" = mkOverride 1002 null;
        "readOnlyRootFilesystem" = mkOverride 1002 null;
        "runAsGroup" = mkOverride 1002 null;
        "runAsNonRoot" = mkOverride 1002 null;
        "runAsUser" = mkOverride 1002 null;
        "seLinuxOptions" = mkOverride 1002 null;
        "seccompProfile" = mkOverride 1002 null;
        "windowsOptions" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContextAppArmorProfile" =
      {

        options = {
          "localhostProfile" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "localhostProfile" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContextCapabilities" =
      {

        options = {
          "add" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "drop" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "add" = mkOverride 1002 null;
          "drop" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContextSeLinuxOptions" =
      {

        options = {
          "level" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "role" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "user" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "level" = mkOverride 1002 null;
          "role" = mkOverride 1002 null;
          "type" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContextSeccompProfile" =
      {

        options = {
          "localhostProfile" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "localhostProfile" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersSecurityContextWindowsOptions" =
      {

        options = {
          "gmsaCredentialSpec" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "gmsaCredentialSpecName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "hostProcess" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "runAsUserName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "gmsaCredentialSpec" = mkOverride 1002 null;
          "gmsaCredentialSpecName" = mkOverride 1002 null;
          "hostProcess" = mkOverride 1002 null;
          "runAsUserName" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbe" = {

      options = {
        "exec" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbeExec"
            )
          );
        };
        "failureThreshold" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "grpc" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbeGrpc"
            )
          );
        };
        "httpGet" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbeHttpGet"
            )
          );
        };
        "initialDelaySeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "periodSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "successThreshold" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "tcpSocket" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbeTcpSocket"
            )
          );
        };
        "terminationGracePeriodSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "timeoutSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "exec" = mkOverride 1002 null;
        "failureThreshold" = mkOverride 1002 null;
        "grpc" = mkOverride 1002 null;
        "httpGet" = mkOverride 1002 null;
        "initialDelaySeconds" = mkOverride 1002 null;
        "periodSeconds" = mkOverride 1002 null;
        "successThreshold" = mkOverride 1002 null;
        "tcpSocket" = mkOverride 1002 null;
        "terminationGracePeriodSeconds" = mkOverride 1002 null;
        "timeoutSeconds" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbeExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbeGrpc" =
      {

        options = {
          "port" = mkOption {
            description = "";
            type = types.int;
          };
          "service" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "service" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbeHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbeHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbeHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersStartupProbeTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersVolumeDevices" = {

      options = {
        "devicePath" = mkOption {
          description = "";
          type = types.str;
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecContainersVolumeMounts" = {

      options = {
        "mountPath" = mkOption {
          description = "";
          type = types.str;
        };
        "mountPropagation" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "recursiveReadOnly" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "subPath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "subPathExpr" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "mountPropagation" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "recursiveReadOnly" = mkOverride 1002 null;
        "subPath" = mkOverride 1002 null;
        "subPathExpr" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecDnsConfig" = {

      options = {
        "nameservers" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "options" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecDnsConfigOptions"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "searches" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "nameservers" = mkOverride 1002 null;
        "options" = mkOverride 1002 null;
        "searches" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecDnsConfigOptions" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "value" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainers" = {

      options = {
        "args" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "command" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "env" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnv"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "envFrom" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvFrom"
              )
            )
          );
        };
        "image" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "imagePullPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "lifecycle" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecycle"
            )
          );
        };
        "livenessProbe" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbe"
            )
          );
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "ports" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersPorts"
                "name"
                [
                  "containerPort"
                  "protocol"
                ]
            )
          );
          apply = attrsToList;
        };
        "readinessProbe" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbe"
            )
          );
        };
        "resizePolicy" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersResizePolicy"
              )
            )
          );
        };
        "resources" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersResources"
            )
          );
        };
        "restartPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "restartPolicyRules" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersRestartPolicyRules"
              )
            )
          );
        };
        "securityContext" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContext"
            )
          );
        };
        "startupProbe" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbe"
            )
          );
        };
        "stdin" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "stdinOnce" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "targetContainerName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "terminationMessagePath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "terminationMessagePolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "tty" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "volumeDevices" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersVolumeDevices"
                "name"
                [ "devicePath" ]
            )
          );
          apply = attrsToList;
        };
        "volumeMounts" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersVolumeMounts"
                "name"
                [ "mountPath" ]
            )
          );
          apply = attrsToList;
        };
        "workingDir" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "args" = mkOverride 1002 null;
        "command" = mkOverride 1002 null;
        "env" = mkOverride 1002 null;
        "envFrom" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "imagePullPolicy" = mkOverride 1002 null;
        "lifecycle" = mkOverride 1002 null;
        "livenessProbe" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
        "readinessProbe" = mkOverride 1002 null;
        "resizePolicy" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "restartPolicy" = mkOverride 1002 null;
        "restartPolicyRules" = mkOverride 1002 null;
        "securityContext" = mkOverride 1002 null;
        "startupProbe" = mkOverride 1002 null;
        "stdin" = mkOverride 1002 null;
        "stdinOnce" = mkOverride 1002 null;
        "targetContainerName" = mkOverride 1002 null;
        "terminationMessagePath" = mkOverride 1002 null;
        "terminationMessagePolicy" = mkOverride 1002 null;
        "tty" = mkOverride 1002 null;
        "volumeDevices" = mkOverride 1002 null;
        "volumeMounts" = mkOverride 1002 null;
        "workingDir" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnv" = {

      options = {
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "value" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "valueFrom" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFrom"
            )
          );
        };
      };

      config = {
        "value" = mkOverride 1002 null;
        "valueFrom" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvFrom" =
      {

        options = {
          "configMapRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvFromConfigMapRef"
              )
            );
          };
          "prefix" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "secretRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvFromSecretRef"
              )
            );
          };
        };

        config = {
          "configMapRef" = mkOverride 1002 null;
          "prefix" = mkOverride 1002 null;
          "secretRef" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvFromConfigMapRef" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvFromSecretRef" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFrom" =
      {

        options = {
          "configMapKeyRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFromConfigMapKeyRef"
              )
            );
          };
          "fieldRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFromFieldRef"
              )
            );
          };
          "fileKeyRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFromFileKeyRef"
              )
            );
          };
          "resourceFieldRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFromResourceFieldRef"
              )
            );
          };
          "secretKeyRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFromSecretKeyRef"
              )
            );
          };
        };

        config = {
          "configMapKeyRef" = mkOverride 1002 null;
          "fieldRef" = mkOverride 1002 null;
          "fileKeyRef" = mkOverride 1002 null;
          "resourceFieldRef" = mkOverride 1002 null;
          "secretKeyRef" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFromConfigMapKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFromFieldRef" =
      {

        options = {
          "apiVersion" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "fieldPath" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "apiVersion" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFromFileKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "path" = mkOption {
            description = "";
            type = types.str;
          };
          "volumeName" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFromResourceFieldRef" =
      {

        options = {
          "containerName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "divisor" = mkOption {
            description = "";
            type = (types.nullOr (types.either types.int types.str));
          };
          "resource" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "containerName" = mkOverride 1002 null;
          "divisor" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersEnvValueFromSecretKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecycle" =
      {

        options = {
          "postStart" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStart"
              )
            );
          };
          "preStop" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStop"
              )
            );
          };
          "stopSignal" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "postStart" = mkOverride 1002 null;
          "preStop" = mkOverride 1002 null;
          "stopSignal" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStart" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStartExec"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStartHttpGet"
              )
            );
          };
          "sleep" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStartSleep"
              )
            );
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStartTcpSocket"
              )
            );
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "sleep" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStartExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStartHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStartHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStartHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStartSleep" =
      {

        options = {
          "seconds" = mkOption {
            description = "";
            type = types.int;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePostStartTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStop" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStopExec"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStopHttpGet"
              )
            );
          };
          "sleep" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStopSleep"
              )
            );
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStopTcpSocket"
              )
            );
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "sleep" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStopExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStopHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStopHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStopHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStopSleep" =
      {

        options = {
          "seconds" = mkOption {
            description = "";
            type = types.int;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLifecyclePreStopTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbe" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbeExec"
              )
            );
          };
          "failureThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "grpc" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbeGrpc"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbeHttpGet"
              )
            );
          };
          "initialDelaySeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "periodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "successThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbeTcpSocket"
              )
            );
          };
          "terminationGracePeriodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "timeoutSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "failureThreshold" = mkOverride 1002 null;
          "grpc" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "initialDelaySeconds" = mkOverride 1002 null;
          "periodSeconds" = mkOverride 1002 null;
          "successThreshold" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
          "terminationGracePeriodSeconds" = mkOverride 1002 null;
          "timeoutSeconds" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbeExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbeGrpc" =
      {

        options = {
          "port" = mkOption {
            description = "";
            type = types.int;
          };
          "service" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "service" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbeHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbeHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbeHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersLivenessProbeTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersPorts" = {

      options = {
        "containerPort" = mkOption {
          description = "";
          type = types.int;
        };
        "hostIP" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "hostPort" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "protocol" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "hostIP" = mkOverride 1002 null;
        "hostPort" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "protocol" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbe" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbeExec"
              )
            );
          };
          "failureThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "grpc" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbeGrpc"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbeHttpGet"
              )
            );
          };
          "initialDelaySeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "periodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "successThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbeTcpSocket"
              )
            );
          };
          "terminationGracePeriodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "timeoutSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "failureThreshold" = mkOverride 1002 null;
          "grpc" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "initialDelaySeconds" = mkOverride 1002 null;
          "periodSeconds" = mkOverride 1002 null;
          "successThreshold" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
          "terminationGracePeriodSeconds" = mkOverride 1002 null;
          "timeoutSeconds" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbeExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbeGrpc" =
      {

        options = {
          "port" = mkOption {
            description = "";
            type = types.int;
          };
          "service" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "service" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbeHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbeHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbeHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersReadinessProbeTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersResizePolicy" =
      {

        options = {
          "resourceName" = mkOption {
            description = "";
            type = types.str;
          };
          "restartPolicy" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersResources" =
      {

        options = {
          "claims" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersResourcesClaims"
                  "name"
                  [ "name" ]
              )
            );
            apply = attrsToList;
          };
          "limits" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
          };
          "requests" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
          };
        };

        config = {
          "claims" = mkOverride 1002 null;
          "limits" = mkOverride 1002 null;
          "requests" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersResourcesClaims" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "request" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "request" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersRestartPolicyRules" =
      {

        options = {
          "action" = mkOption {
            description = "";
            type = types.str;
          };
          "exitCodes" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersRestartPolicyRulesExitCodes"
              )
            );
          };
        };

        config = {
          "exitCodes" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersRestartPolicyRulesExitCodes" =
      {

        options = {
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.int));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContext" =
      {

        options = {
          "allowPrivilegeEscalation" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "appArmorProfile" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContextAppArmorProfile"
              )
            );
          };
          "capabilities" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContextCapabilities"
              )
            );
          };
          "privileged" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "procMount" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "readOnlyRootFilesystem" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "runAsGroup" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "runAsNonRoot" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "runAsUser" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "seLinuxOptions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContextSeLinuxOptions"
              )
            );
          };
          "seccompProfile" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContextSeccompProfile"
              )
            );
          };
          "windowsOptions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContextWindowsOptions"
              )
            );
          };
        };

        config = {
          "allowPrivilegeEscalation" = mkOverride 1002 null;
          "appArmorProfile" = mkOverride 1002 null;
          "capabilities" = mkOverride 1002 null;
          "privileged" = mkOverride 1002 null;
          "procMount" = mkOverride 1002 null;
          "readOnlyRootFilesystem" = mkOverride 1002 null;
          "runAsGroup" = mkOverride 1002 null;
          "runAsNonRoot" = mkOverride 1002 null;
          "runAsUser" = mkOverride 1002 null;
          "seLinuxOptions" = mkOverride 1002 null;
          "seccompProfile" = mkOverride 1002 null;
          "windowsOptions" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContextAppArmorProfile" =
      {

        options = {
          "localhostProfile" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "localhostProfile" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContextCapabilities" =
      {

        options = {
          "add" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "drop" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "add" = mkOverride 1002 null;
          "drop" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContextSeLinuxOptions" =
      {

        options = {
          "level" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "role" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "user" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "level" = mkOverride 1002 null;
          "role" = mkOverride 1002 null;
          "type" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContextSeccompProfile" =
      {

        options = {
          "localhostProfile" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "localhostProfile" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersSecurityContextWindowsOptions" =
      {

        options = {
          "gmsaCredentialSpec" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "gmsaCredentialSpecName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "hostProcess" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "runAsUserName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "gmsaCredentialSpec" = mkOverride 1002 null;
          "gmsaCredentialSpecName" = mkOverride 1002 null;
          "hostProcess" = mkOverride 1002 null;
          "runAsUserName" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbe" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbeExec"
              )
            );
          };
          "failureThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "grpc" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbeGrpc"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbeHttpGet"
              )
            );
          };
          "initialDelaySeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "periodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "successThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbeTcpSocket"
              )
            );
          };
          "terminationGracePeriodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "timeoutSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "failureThreshold" = mkOverride 1002 null;
          "grpc" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "initialDelaySeconds" = mkOverride 1002 null;
          "periodSeconds" = mkOverride 1002 null;
          "successThreshold" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
          "terminationGracePeriodSeconds" = mkOverride 1002 null;
          "timeoutSeconds" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbeExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbeGrpc" =
      {

        options = {
          "port" = mkOption {
            description = "";
            type = types.int;
          };
          "service" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "service" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbeHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbeHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbeHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersStartupProbeTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersVolumeDevices" =
      {

        options = {
          "devicePath" = mkOption {
            description = "";
            type = types.str;
          };
          "name" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecEphemeralContainersVolumeMounts" =
      {

        options = {
          "mountPath" = mkOption {
            description = "";
            type = types.str;
          };
          "mountPropagation" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "readOnly" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "recursiveReadOnly" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "subPath" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "subPathExpr" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "mountPropagation" = mkOverride 1002 null;
          "readOnly" = mkOverride 1002 null;
          "recursiveReadOnly" = mkOverride 1002 null;
          "subPath" = mkOverride 1002 null;
          "subPathExpr" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecHostAliases" = {

      options = {
        "hostnames" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "ip" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "hostnames" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecImagePullSecrets" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainers" = {

      options = {
        "args" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "command" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "env" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnv"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "envFrom" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvFrom"
              )
            )
          );
        };
        "image" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "imagePullPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "lifecycle" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecycle"
            )
          );
        };
        "livenessProbe" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbe"
            )
          );
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "ports" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersPorts"
                "name"
                [
                  "containerPort"
                  "protocol"
                ]
            )
          );
          apply = attrsToList;
        };
        "readinessProbe" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbe"
            )
          );
        };
        "resizePolicy" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersResizePolicy"
              )
            )
          );
        };
        "resources" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersResources"
            )
          );
        };
        "restartPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "restartPolicyRules" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersRestartPolicyRules"
              )
            )
          );
        };
        "securityContext" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContext"
            )
          );
        };
        "startupProbe" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbe"
            )
          );
        };
        "stdin" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "stdinOnce" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "terminationMessagePath" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "terminationMessagePolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "tty" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "volumeDevices" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersVolumeDevices"
                "name"
                [ "devicePath" ]
            )
          );
          apply = attrsToList;
        };
        "volumeMounts" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersVolumeMounts"
                "name"
                [ "mountPath" ]
            )
          );
          apply = attrsToList;
        };
        "workingDir" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "args" = mkOverride 1002 null;
        "command" = mkOverride 1002 null;
        "env" = mkOverride 1002 null;
        "envFrom" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "imagePullPolicy" = mkOverride 1002 null;
        "lifecycle" = mkOverride 1002 null;
        "livenessProbe" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
        "readinessProbe" = mkOverride 1002 null;
        "resizePolicy" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "restartPolicy" = mkOverride 1002 null;
        "restartPolicyRules" = mkOverride 1002 null;
        "securityContext" = mkOverride 1002 null;
        "startupProbe" = mkOverride 1002 null;
        "stdin" = mkOverride 1002 null;
        "stdinOnce" = mkOverride 1002 null;
        "terminationMessagePath" = mkOverride 1002 null;
        "terminationMessagePolicy" = mkOverride 1002 null;
        "tty" = mkOverride 1002 null;
        "volumeDevices" = mkOverride 1002 null;
        "volumeMounts" = mkOverride 1002 null;
        "workingDir" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnv" = {

      options = {
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "value" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "valueFrom" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFrom"
            )
          );
        };
      };

      config = {
        "value" = mkOverride 1002 null;
        "valueFrom" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvFrom" = {

      options = {
        "configMapRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvFromConfigMapRef"
            )
          );
        };
        "prefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvFromSecretRef"
            )
          );
        };
      };

      config = {
        "configMapRef" = mkOverride 1002 null;
        "prefix" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvFromConfigMapRef" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvFromSecretRef" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFrom" =
      {

        options = {
          "configMapKeyRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFromConfigMapKeyRef"
              )
            );
          };
          "fieldRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFromFieldRef"
              )
            );
          };
          "fileKeyRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFromFileKeyRef"
              )
            );
          };
          "resourceFieldRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFromResourceFieldRef"
              )
            );
          };
          "secretKeyRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFromSecretKeyRef"
              )
            );
          };
        };

        config = {
          "configMapKeyRef" = mkOverride 1002 null;
          "fieldRef" = mkOverride 1002 null;
          "fileKeyRef" = mkOverride 1002 null;
          "resourceFieldRef" = mkOverride 1002 null;
          "secretKeyRef" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFromConfigMapKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFromFieldRef" =
      {

        options = {
          "apiVersion" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "fieldPath" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "apiVersion" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFromFileKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "path" = mkOption {
            description = "";
            type = types.str;
          };
          "volumeName" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFromResourceFieldRef" =
      {

        options = {
          "containerName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "divisor" = mkOption {
            description = "";
            type = (types.nullOr (types.either types.int types.str));
          };
          "resource" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "containerName" = mkOverride 1002 null;
          "divisor" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersEnvValueFromSecretKeyRef" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecycle" = {

      options = {
        "postStart" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStart"
            )
          );
        };
        "preStop" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStop"
            )
          );
        };
        "stopSignal" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "postStart" = mkOverride 1002 null;
        "preStop" = mkOverride 1002 null;
        "stopSignal" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStart" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStartExec"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStartHttpGet"
              )
            );
          };
          "sleep" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStartSleep"
              )
            );
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStartTcpSocket"
              )
            );
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "sleep" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStartExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStartHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStartHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStartHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStartSleep" =
      {

        options = {
          "seconds" = mkOption {
            description = "";
            type = types.int;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePostStartTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStop" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStopExec"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStopHttpGet"
              )
            );
          };
          "sleep" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStopSleep"
              )
            );
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStopTcpSocket"
              )
            );
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "sleep" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStopExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStopHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStopHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStopHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStopSleep" =
      {

        options = {
          "seconds" = mkOption {
            description = "";
            type = types.int;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLifecyclePreStopTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbe" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbeExec"
              )
            );
          };
          "failureThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "grpc" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbeGrpc"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbeHttpGet"
              )
            );
          };
          "initialDelaySeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "periodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "successThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbeTcpSocket"
              )
            );
          };
          "terminationGracePeriodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "timeoutSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "failureThreshold" = mkOverride 1002 null;
          "grpc" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "initialDelaySeconds" = mkOverride 1002 null;
          "periodSeconds" = mkOverride 1002 null;
          "successThreshold" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
          "terminationGracePeriodSeconds" = mkOverride 1002 null;
          "timeoutSeconds" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbeExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbeGrpc" =
      {

        options = {
          "port" = mkOption {
            description = "";
            type = types.int;
          };
          "service" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "service" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbeHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbeHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbeHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersLivenessProbeTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersPorts" = {

      options = {
        "containerPort" = mkOption {
          description = "";
          type = types.int;
        };
        "hostIP" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "hostPort" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "protocol" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "hostIP" = mkOverride 1002 null;
        "hostPort" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "protocol" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbe" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbeExec"
              )
            );
          };
          "failureThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "grpc" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbeGrpc"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbeHttpGet"
              )
            );
          };
          "initialDelaySeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "periodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "successThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbeTcpSocket"
              )
            );
          };
          "terminationGracePeriodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "timeoutSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "failureThreshold" = mkOverride 1002 null;
          "grpc" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "initialDelaySeconds" = mkOverride 1002 null;
          "periodSeconds" = mkOverride 1002 null;
          "successThreshold" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
          "terminationGracePeriodSeconds" = mkOverride 1002 null;
          "timeoutSeconds" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbeExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbeGrpc" =
      {

        options = {
          "port" = mkOption {
            description = "";
            type = types.int;
          };
          "service" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "service" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbeHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbeHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbeHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersReadinessProbeTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersResizePolicy" =
      {

        options = {
          "resourceName" = mkOption {
            description = "";
            type = types.str;
          };
          "restartPolicy" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersResources" = {

      options = {
        "claims" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersResourcesClaims"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "limits" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "requests" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
      };

      config = {
        "claims" = mkOverride 1002 null;
        "limits" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersResourcesClaims" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "request" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "request" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersRestartPolicyRules" =
      {

        options = {
          "action" = mkOption {
            description = "";
            type = types.str;
          };
          "exitCodes" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersRestartPolicyRulesExitCodes"
              )
            );
          };
        };

        config = {
          "exitCodes" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersRestartPolicyRulesExitCodes" =
      {

        options = {
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.int));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContext" =
      {

        options = {
          "allowPrivilegeEscalation" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "appArmorProfile" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContextAppArmorProfile"
              )
            );
          };
          "capabilities" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContextCapabilities"
              )
            );
          };
          "privileged" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "procMount" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "readOnlyRootFilesystem" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "runAsGroup" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "runAsNonRoot" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "runAsUser" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "seLinuxOptions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContextSeLinuxOptions"
              )
            );
          };
          "seccompProfile" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContextSeccompProfile"
              )
            );
          };
          "windowsOptions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContextWindowsOptions"
              )
            );
          };
        };

        config = {
          "allowPrivilegeEscalation" = mkOverride 1002 null;
          "appArmorProfile" = mkOverride 1002 null;
          "capabilities" = mkOverride 1002 null;
          "privileged" = mkOverride 1002 null;
          "procMount" = mkOverride 1002 null;
          "readOnlyRootFilesystem" = mkOverride 1002 null;
          "runAsGroup" = mkOverride 1002 null;
          "runAsNonRoot" = mkOverride 1002 null;
          "runAsUser" = mkOverride 1002 null;
          "seLinuxOptions" = mkOverride 1002 null;
          "seccompProfile" = mkOverride 1002 null;
          "windowsOptions" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContextAppArmorProfile" =
      {

        options = {
          "localhostProfile" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "localhostProfile" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContextCapabilities" =
      {

        options = {
          "add" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "drop" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "add" = mkOverride 1002 null;
          "drop" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContextSeLinuxOptions" =
      {

        options = {
          "level" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "role" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "user" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "level" = mkOverride 1002 null;
          "role" = mkOverride 1002 null;
          "type" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContextSeccompProfile" =
      {

        options = {
          "localhostProfile" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "localhostProfile" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersSecurityContextWindowsOptions" =
      {

        options = {
          "gmsaCredentialSpec" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "gmsaCredentialSpecName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "hostProcess" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "runAsUserName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "gmsaCredentialSpec" = mkOverride 1002 null;
          "gmsaCredentialSpecName" = mkOverride 1002 null;
          "hostProcess" = mkOverride 1002 null;
          "runAsUserName" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbe" =
      {

        options = {
          "exec" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbeExec"
              )
            );
          };
          "failureThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "grpc" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbeGrpc"
              )
            );
          };
          "httpGet" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbeHttpGet"
              )
            );
          };
          "initialDelaySeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "periodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "successThreshold" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "tcpSocket" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbeTcpSocket"
              )
            );
          };
          "terminationGracePeriodSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "timeoutSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "exec" = mkOverride 1002 null;
          "failureThreshold" = mkOverride 1002 null;
          "grpc" = mkOverride 1002 null;
          "httpGet" = mkOverride 1002 null;
          "initialDelaySeconds" = mkOverride 1002 null;
          "periodSeconds" = mkOverride 1002 null;
          "successThreshold" = mkOverride 1002 null;
          "tcpSocket" = mkOverride 1002 null;
          "terminationGracePeriodSeconds" = mkOverride 1002 null;
          "timeoutSeconds" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbeExec" =
      {

        options = {
          "command" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "command" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbeGrpc" =
      {

        options = {
          "port" = mkOption {
            description = "";
            type = types.int;
          };
          "service" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "service" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbeHttpGet" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "httpHeaders" = mkOption {
            description = "";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbeHttpGetHttpHeaders"
                  "name"
                  [ ]
              )
            );
            apply = attrsToList;
          };
          "path" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
          "scheme" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
          "httpHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
          "scheme" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbeHttpGetHttpHeaders" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "value" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersStartupProbeTcpSocket" =
      {

        options = {
          "host" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "port" = mkOption {
            description = "";
            type = (types.either types.int types.str);
          };
        };

        config = {
          "host" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersVolumeDevices" =
      {

        options = {
          "devicePath" = mkOption {
            description = "";
            type = types.str;
          };
          "name" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecInitContainersVolumeMounts" =
      {

        options = {
          "mountPath" = mkOption {
            description = "";
            type = types.str;
          };
          "mountPropagation" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "readOnly" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "recursiveReadOnly" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "subPath" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "subPathExpr" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "mountPropagation" = mkOverride 1002 null;
          "readOnly" = mkOverride 1002 null;
          "recursiveReadOnly" = mkOverride 1002 null;
          "subPath" = mkOverride 1002 null;
          "subPathExpr" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecOs" = {

      options = {
        "name" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecReadinessGates" = {

      options = {
        "conditionType" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContext" = {

      options = {
        "appArmorProfile" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContextAppArmorProfile"
            )
          );
        };
        "fsGroup" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "fsGroupChangePolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "runAsGroup" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "seLinuxChangePolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "seLinuxOptions" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContextSeLinuxOptions"
            )
          );
        };
        "seccompProfile" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContextSeccompProfile"
            )
          );
        };
        "supplementalGroups" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.int));
        };
        "supplementalGroupsPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "sysctls" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContextSysctls"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "windowsOptions" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContextWindowsOptions"
            )
          );
        };
      };

      config = {
        "appArmorProfile" = mkOverride 1002 null;
        "fsGroup" = mkOverride 1002 null;
        "fsGroupChangePolicy" = mkOverride 1002 null;
        "runAsGroup" = mkOverride 1002 null;
        "runAsNonRoot" = mkOverride 1002 null;
        "runAsUser" = mkOverride 1002 null;
        "seLinuxChangePolicy" = mkOverride 1002 null;
        "seLinuxOptions" = mkOverride 1002 null;
        "seccompProfile" = mkOverride 1002 null;
        "supplementalGroups" = mkOverride 1002 null;
        "supplementalGroupsPolicy" = mkOverride 1002 null;
        "sysctls" = mkOverride 1002 null;
        "windowsOptions" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContextAppArmorProfile" =
      {

        options = {
          "localhostProfile" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "localhostProfile" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContextSeLinuxOptions" =
      {

        options = {
          "level" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "role" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "user" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "level" = mkOverride 1002 null;
          "role" = mkOverride 1002 null;
          "type" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContextSeccompProfile" =
      {

        options = {
          "localhostProfile" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "type" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "localhostProfile" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContextSysctls" = {

      options = {
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "value" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecSecurityContextWindowsOptions" =
      {

        options = {
          "gmsaCredentialSpec" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "gmsaCredentialSpecName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "hostProcess" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "runAsUserName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "gmsaCredentialSpec" = mkOverride 1002 null;
          "gmsaCredentialSpecName" = mkOverride 1002 null;
          "hostProcess" = mkOverride 1002 null;
          "runAsUserName" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecTolerations" = {

      options = {
        "effect" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "operator" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "tolerationSeconds" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "value" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "effect" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "operator" = mkOverride 1002 null;
        "tolerationSeconds" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecTopologySpreadConstraints" = {

      options = {
        "labelSelector" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecTopologySpreadConstraintsLabelSelector"
            )
          );
        };
        "matchLabelKeys" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "maxSkew" = mkOption {
          description = "";
          type = types.int;
        };
        "minDomains" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "nodeAffinityPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "nodeTaintsPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "topologyKey" = mkOption {
          description = "";
          type = types.str;
        };
        "whenUnsatisfiable" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "labelSelector" = mkOverride 1002 null;
        "matchLabelKeys" = mkOverride 1002 null;
        "minDomains" = mkOverride 1002 null;
        "nodeAffinityPolicy" = mkOverride 1002 null;
        "nodeTaintsPolicy" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecTopologySpreadConstraintsLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecTopologySpreadConstraintsLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecTopologySpreadConstraintsLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumes" = {

      options = {
        "awsElasticBlockStore" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesAwsElasticBlockStore"
            )
          );
        };
        "azureDisk" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesAzureDisk"
            )
          );
        };
        "azureFile" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesAzureFile"
            )
          );
        };
        "cephfs" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCephfs"
            )
          );
        };
        "cinder" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCinder"
            )
          );
        };
        "configMap" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesConfigMap"
            )
          );
        };
        "csi" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCsi"
            )
          );
        };
        "downwardAPI" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesDownwardAPI"
            )
          );
        };
        "emptyDir" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEmptyDir"
            )
          );
        };
        "ephemeral" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeral"
            )
          );
        };
        "fc" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesFc"
            )
          );
        };
        "flexVolume" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesFlexVolume"
            )
          );
        };
        "flocker" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesFlocker"
            )
          );
        };
        "gcePersistentDisk" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesGcePersistentDisk"
            )
          );
        };
        "gitRepo" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesGitRepo"
            )
          );
        };
        "glusterfs" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesGlusterfs"
            )
          );
        };
        "hostPath" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesHostPath"
            )
          );
        };
        "image" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesImage"
            )
          );
        };
        "iscsi" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesIscsi"
            )
          );
        };
        "name" = mkOption {
          description = "";
          type = types.str;
        };
        "nfs" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesNfs"
            )
          );
        };
        "persistentVolumeClaim" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesPersistentVolumeClaim"
            )
          );
        };
        "photonPersistentDisk" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesPhotonPersistentDisk"
            )
          );
        };
        "portworxVolume" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesPortworxVolume"
            )
          );
        };
        "projected" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjected"
            )
          );
        };
        "quobyte" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesQuobyte"
            )
          );
        };
        "rbd" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesRbd"
            )
          );
        };
        "scaleIO" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesScaleIO"
            )
          );
        };
        "secret" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesSecret"
            )
          );
        };
        "storageos" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesStorageos"
            )
          );
        };
        "vsphereVolume" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesVsphereVolume"
            )
          );
        };
      };

      config = {
        "awsElasticBlockStore" = mkOverride 1002 null;
        "azureDisk" = mkOverride 1002 null;
        "azureFile" = mkOverride 1002 null;
        "cephfs" = mkOverride 1002 null;
        "cinder" = mkOverride 1002 null;
        "configMap" = mkOverride 1002 null;
        "csi" = mkOverride 1002 null;
        "downwardAPI" = mkOverride 1002 null;
        "emptyDir" = mkOverride 1002 null;
        "ephemeral" = mkOverride 1002 null;
        "fc" = mkOverride 1002 null;
        "flexVolume" = mkOverride 1002 null;
        "flocker" = mkOverride 1002 null;
        "gcePersistentDisk" = mkOverride 1002 null;
        "gitRepo" = mkOverride 1002 null;
        "glusterfs" = mkOverride 1002 null;
        "hostPath" = mkOverride 1002 null;
        "image" = mkOverride 1002 null;
        "iscsi" = mkOverride 1002 null;
        "nfs" = mkOverride 1002 null;
        "persistentVolumeClaim" = mkOverride 1002 null;
        "photonPersistentDisk" = mkOverride 1002 null;
        "portworxVolume" = mkOverride 1002 null;
        "projected" = mkOverride 1002 null;
        "quobyte" = mkOverride 1002 null;
        "rbd" = mkOverride 1002 null;
        "scaleIO" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
        "storageos" = mkOverride 1002 null;
        "vsphereVolume" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesAwsElasticBlockStore" =
      {

        options = {
          "fsType" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "partition" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "readOnly" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "volumeID" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "fsType" = mkOverride 1002 null;
          "partition" = mkOverride 1002 null;
          "readOnly" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesAzureDisk" = {

      options = {
        "cachingMode" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "diskName" = mkOption {
          description = "";
          type = types.str;
        };
        "diskURI" = mkOption {
          description = "";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "cachingMode" = mkOverride 1002 null;
        "fsType" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesAzureFile" = {

      options = {
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "secretName" = mkOption {
          description = "";
          type = types.str;
        };
        "shareName" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCephfs" = {

      options = {
        "monitors" = mkOption {
          description = "";
          type = (types.listOf types.str);
        };
        "path" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "secretFile" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCephfsSecretRef"
            )
          );
        };
        "user" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "path" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretFile" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCephfsSecretRef" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCinder" = {

      options = {
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCinderSecretRef"
            )
          );
        };
        "volumeID" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCinderSecretRef" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesConfigMap" = {

      options = {
        "defaultMode" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesConfigMapItems"
              )
            )
          );
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesConfigMapItems" = {

      options = {
        "key" = mkOption {
          description = "";
          type = types.str;
        };
        "mode" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "mode" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCsi" = {

      options = {
        "driver" = mkOption {
          description = "";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "nodePublishSecretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCsiNodePublishSecretRef"
            )
          );
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "volumeAttributes" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "nodePublishSecretRef" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "volumeAttributes" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesCsiNodePublishSecretRef" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesDownwardAPI" = {

      options = {
        "defaultMode" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesDownwardAPIItems"
              )
            )
          );
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesDownwardAPIItems" = {

      options = {
        "fieldRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesDownwardAPIItemsFieldRef"
            )
          );
        };
        "mode" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "";
          type = types.str;
        };
        "resourceFieldRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesDownwardAPIItemsResourceFieldRef"
            )
          );
        };
      };

      config = {
        "fieldRef" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "resourceFieldRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesDownwardAPIItemsFieldRef" =
      {

        options = {
          "apiVersion" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "fieldPath" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "apiVersion" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesDownwardAPIItemsResourceFieldRef" =
      {

        options = {
          "containerName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "divisor" = mkOption {
            description = "";
            type = (types.nullOr (types.either types.int types.str));
          };
          "resource" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "containerName" = mkOverride 1002 null;
          "divisor" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEmptyDir" = {

      options = {
        "medium" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "sizeLimit" = mkOption {
          description = "";
          type = (types.nullOr (types.either types.int types.str));
        };
      };

      config = {
        "medium" = mkOverride 1002 null;
        "sizeLimit" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeral" = {

      options = {
        "volumeClaimTemplate" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplate"
            )
          );
        };
      };

      config = {
        "volumeClaimTemplate" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplate" =
      {

        options = {
          "metadata" = mkOption {
            description = "";
            type = (types.nullOr types.attrs);
          };
          "spec" = mkOption {
            description = "";
            type = (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpec"
            );
          };
        };

        config = {
          "metadata" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpec" =
      {

        options = {
          "accessModes" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
          "dataSource" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpecDataSource"
              )
            );
          };
          "dataSourceRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpecDataSourceRef"
              )
            );
          };
          "resources" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpecResources"
              )
            );
          };
          "selector" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpecSelector"
              )
            );
          };
          "storageClassName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "volumeAttributesClassName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "volumeMode" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "volumeName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "accessModes" = mkOverride 1002 null;
          "dataSource" = mkOverride 1002 null;
          "dataSourceRef" = mkOverride 1002 null;
          "resources" = mkOverride 1002 null;
          "selector" = mkOverride 1002 null;
          "storageClassName" = mkOverride 1002 null;
          "volumeAttributesClassName" = mkOverride 1002 null;
          "volumeMode" = mkOverride 1002 null;
          "volumeName" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpecDataSource" =
      {

        options = {
          "apiGroup" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "kind" = mkOption {
            description = "";
            type = types.str;
          };
          "name" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "apiGroup" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpecDataSourceRef" =
      {

        options = {
          "apiGroup" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "kind" = mkOption {
            description = "";
            type = types.str;
          };
          "name" = mkOption {
            description = "";
            type = types.str;
          };
          "namespace" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "apiGroup" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpecResources" =
      {

        options = {
          "limits" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
          };
          "requests" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
          };
        };

        config = {
          "limits" = mkOverride 1002 null;
          "requests" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpecSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpecSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesEphemeralVolumeClaimTemplateSpecSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesFc" = {

      options = {
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "lun" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "targetWWNs" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "wwids" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "lun" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "targetWWNs" = mkOverride 1002 null;
        "wwids" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesFlexVolume" = {

      options = {
        "driver" = mkOption {
          description = "";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "options" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesFlexVolumeSecretRef"
            )
          );
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "options" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesFlexVolumeSecretRef" =
      {

        options = {
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "name" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesFlocker" = {

      options = {
        "datasetName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "datasetUUID" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "datasetName" = mkOverride 1002 null;
        "datasetUUID" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesGcePersistentDisk" = {

      options = {
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "partition" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "pdName" = mkOption {
          description = "";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "partition" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesGitRepo" = {

      options = {
        "directory" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "repository" = mkOption {
          description = "";
          type = types.str;
        };
        "revision" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "directory" = mkOverride 1002 null;
        "revision" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesGlusterfs" = {

      options = {
        "endpoints" = mkOption {
          description = "";
          type = types.str;
        };
        "path" = mkOption {
          description = "";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesHostPath" = {

      options = {
        "path" = mkOption {
          description = "";
          type = types.str;
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesImage" = {

      options = {
        "pullPolicy" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reference" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "pullPolicy" = mkOverride 1002 null;
        "reference" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesIscsi" = {

      options = {
        "chapAuthDiscovery" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "chapAuthSession" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "initiatorName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "iqn" = mkOption {
          description = "";
          type = types.str;
        };
        "iscsiInterface" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "lun" = mkOption {
          description = "";
          type = types.int;
        };
        "portals" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesIscsiSecretRef"
            )
          );
        };
        "targetPortal" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "chapAuthDiscovery" = mkOverride 1002 null;
        "chapAuthSession" = mkOverride 1002 null;
        "fsType" = mkOverride 1002 null;
        "initiatorName" = mkOverride 1002 null;
        "iscsiInterface" = mkOverride 1002 null;
        "portals" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesIscsiSecretRef" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesNfs" = {

      options = {
        "path" = mkOption {
          description = "";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "server" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesPersistentVolumeClaim" =
      {

        options = {
          "claimName" = mkOption {
            description = "";
            type = types.str;
          };
          "readOnly" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "readOnly" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesPhotonPersistentDisk" =
      {

        options = {
          "fsType" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "pdID" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "fsType" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesPortworxVolume" = {

      options = {
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "volumeID" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjected" = {

      options = {
        "defaultMode" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "sources" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSources"
              )
            )
          );
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "sources" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSources" = {

      options = {
        "clusterTrustBundle" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesClusterTrustBundle"
            )
          );
        };
        "configMap" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesConfigMap"
            )
          );
        };
        "downwardAPI" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesDownwardAPI"
            )
          );
        };
        "podCertificate" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesPodCertificate"
            )
          );
        };
        "secret" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesSecret"
            )
          );
        };
        "serviceAccountToken" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesServiceAccountToken"
            )
          );
        };
      };

      config = {
        "clusterTrustBundle" = mkOverride 1002 null;
        "configMap" = mkOverride 1002 null;
        "downwardAPI" = mkOverride 1002 null;
        "podCertificate" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
        "serviceAccountToken" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesClusterTrustBundle" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesClusterTrustBundleLabelSelector"
              )
            );
          };
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
          "path" = mkOption {
            description = "";
            type = types.str;
          };
          "signerName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
          "signerName" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesClusterTrustBundleLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesClusterTrustBundleLabelSelectorMatchExpressions"
                )
              )
            );
          };
          "matchLabels" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "matchExpressions" = mkOverride 1002 null;
          "matchLabels" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesClusterTrustBundleLabelSelectorMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "operator" = mkOption {
            description = "";
            type = types.str;
          };
          "values" = mkOption {
            description = "";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesConfigMap" =
      {

        options = {
          "items" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesConfigMapItems"
                )
              )
            );
          };
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "items" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesConfigMapItems" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "mode" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "path" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "mode" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesDownwardAPI" =
      {

        options = {
          "items" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesDownwardAPIItems"
                )
              )
            );
          };
        };

        config = {
          "items" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesDownwardAPIItems" =
      {

        options = {
          "fieldRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesDownwardAPIItemsFieldRef"
              )
            );
          };
          "mode" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "path" = mkOption {
            description = "";
            type = types.str;
          };
          "resourceFieldRef" = mkOption {
            description = "";
            type = (
              types.nullOr (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesDownwardAPIItemsResourceFieldRef"
              )
            );
          };
        };

        config = {
          "fieldRef" = mkOverride 1002 null;
          "mode" = mkOverride 1002 null;
          "resourceFieldRef" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesDownwardAPIItemsFieldRef" =
      {

        options = {
          "apiVersion" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "fieldPath" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "apiVersion" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesDownwardAPIItemsResourceFieldRef" =
      {

        options = {
          "containerName" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "divisor" = mkOption {
            description = "";
            type = (types.nullOr (types.either types.int types.str));
          };
          "resource" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "containerName" = mkOverride 1002 null;
          "divisor" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesPodCertificate" =
      {

        options = {
          "certificateChainPath" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "credentialBundlePath" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "keyPath" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "keyType" = mkOption {
            description = "";
            type = types.str;
          };
          "maxExpirationSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "signerName" = mkOption {
            description = "";
            type = types.str;
          };
          "userAnnotations" = mkOption {
            description = "";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "certificateChainPath" = mkOverride 1002 null;
          "credentialBundlePath" = mkOverride 1002 null;
          "keyPath" = mkOverride 1002 null;
          "maxExpirationSeconds" = mkOverride 1002 null;
          "userAnnotations" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesSecret" =
      {

        options = {
          "items" = mkOption {
            description = "";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesSecretItems"
                )
              )
            );
          };
          "name" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "";
            type = (types.nullOr types.bool);
          };
        };

        config = {
          "items" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesSecretItems" =
      {

        options = {
          "key" = mkOption {
            description = "";
            type = types.str;
          };
          "mode" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "path" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "mode" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesProjectedSourcesServiceAccountToken" =
      {

        options = {
          "audience" = mkOption {
            description = "";
            type = (types.nullOr types.str);
          };
          "expirationSeconds" = mkOption {
            description = "";
            type = (types.nullOr types.int);
          };
          "path" = mkOption {
            description = "";
            type = types.str;
          };
        };

        config = {
          "audience" = mkOverride 1002 null;
          "expirationSeconds" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesQuobyte" = {

      options = {
        "group" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "registry" = mkOption {
          description = "";
          type = types.str;
        };
        "tenant" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "volume" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "tenant" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesRbd" = {

      options = {
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "image" = mkOption {
          description = "";
          type = types.str;
        };
        "keyring" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "monitors" = mkOption {
          description = "";
          type = (types.listOf types.str);
        };
        "pool" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesRbdSecretRef"
            )
          );
        };
        "user" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "keyring" = mkOverride 1002 null;
        "pool" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesRbdSecretRef" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesScaleIO" = {

      options = {
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "gateway" = mkOption {
          description = "";
          type = types.str;
        };
        "protectionDomain" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "";
          type = (
            submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesScaleIOSecretRef"
          );
        };
        "sslEnabled" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "storageMode" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "storagePool" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "system" = mkOption {
          description = "";
          type = types.str;
        };
        "volumeName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "protectionDomain" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "sslEnabled" = mkOverride 1002 null;
        "storageMode" = mkOverride 1002 null;
        "storagePool" = mkOverride 1002 null;
        "volumeName" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesScaleIOSecretRef" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesSecret" = {

      options = {
        "defaultMode" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesSecretItems"
              )
            )
          );
        };
        "optional" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "secretName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesSecretItems" = {

      options = {
        "key" = mkOption {
          description = "";
          type = types.str;
        };
        "mode" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "mode" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesStorageos" = {

      options = {
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesStorageosSecretRef"
            )
          );
        };
        "volumeName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "volumeNamespace" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
        "volumeName" = mkOverride 1002 null;
        "volumeNamespace" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesStorageosSecretRef" = {

      options = {
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecDeploymentSpecTemplateSpecVolumesVsphereVolume" = {

      options = {
        "fsType" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "storagePolicyID" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "storagePolicyName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "volumePath" = mkOption {
          description = "";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "storagePolicyID" = mkOverride 1002 null;
        "storagePolicyName" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecExternal" = {

      options = {
        "adminPassword" = mkOption {
          description = "AdminPassword key to talk to the external grafana instance.";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecExternalAdminPassword")
          );
        };
        "adminUser" = mkOption {
          description = "AdminUser key to talk to the external grafana instance.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecExternalAdminUser"));
        };
        "apiKey" = mkOption {
          description = "The API key to talk to the external grafana instance, you need to define ether apiKey or adminUser/adminPassword.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecExternalApiKey"));
        };
        "tenantNamespace" = mkOption {
          description = "TenantNamespace is used as the `namespace` value for GrafanaManifest resources in multi-tenant scenarios\ndefaults to `default`";
          type = (types.nullOr types.str);
        };
        "tls" = mkOption {
          description = "DEPRECATED, use top level `tls` instead.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecExternalTls"));
        };
        "url" = mkOption {
          description = "URL of the external grafana instance you want to manage.";
          type = types.str;
        };
      };

      config = {
        "adminPassword" = mkOverride 1002 null;
        "adminUser" = mkOverride 1002 null;
        "apiKey" = mkOverride 1002 null;
        "tenantNamespace" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecExternalAdminPassword" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecExternalAdminUser" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecExternalApiKey" = {

      options = {
        "key" = mkOption {
          description = "The key of the secret to select from.  Must be a valid secret key.";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecExternalTls" = {

      options = {
        "certSecretRef" = mkOption {
          description = "Use a secret as a reference to give TLS Certificate information";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecExternalTlsCertSecretRef")
          );
        };
        "insecureSkipVerify" = mkOption {
          description = "Disable the CA check of the server";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "certSecretRef" = mkOverride 1002 null;
        "insecureSkipVerify" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecExternalTlsCertSecretRef" = {

      options = {
        "name" = mkOption {
          description = "name is unique within a namespace to reference a secret resource.";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "namespace defines the space within which the secret name must be unique.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRoute" = {

      options = {
        "metadata" = mkOption {
          description = "ObjectMeta contains only a [subset of the fields included in k8s.io/apimachinery/pkg/apis/meta/v1.ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#objectmeta-v1-meta).";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteMetadata"));
        };
        "spec" = mkOption {
          description = "HTTPRouteSpec defines the desired state of HTTPRoute";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpec"));
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpec" = {

      options = {
        "hostnames" = mkOption {
          description = "Hostnames defines a set of hostnames that should match against the HTTP Host\nheader to select a HTTPRoute used to process the request. Implementations\nMUST ignore any port value specified in the HTTP Host header while\nperforming a match and (absent of any applicable header modification\nconfiguration) MUST forward this header unmodified to the backend.\n\nValid values for Hostnames are determined by RFC 1123 definition of a\nhostname with 2 notable exceptions:\n\n1. IPs are not allowed.\n2. A hostname may be prefixed with a wildcard label (`*.`). The wildcard\n   label must appear by itself as the first label.\n\nIf a hostname is specified by both the Listener and HTTPRoute, there\nmust be at least one intersecting hostname for the HTTPRoute to be\nattached to the Listener. For example:\n\n* A Listener with `test.example.com` as the hostname matches HTTPRoutes\n  that have either not specified any hostnames, or have specified at\n  least one of `test.example.com` or `*.example.com`.\n* A Listener with `*.example.com` as the hostname matches HTTPRoutes\n  that have either not specified any hostnames or have specified at least\n  one hostname that matches the Listener hostname. For example,\n  `*.example.com`, `test.example.com`, and `foo.test.example.com` would\n  all match. On the other hand, `example.com` and `test.example.net` would\n  not match.\n\nHostnames that are prefixed with a wildcard label (`*.`) are interpreted\nas a suffix match. That means that a match for `*.example.com` would match\nboth `test.example.com`, and `foo.test.example.com`, but not `example.com`.\n\nIf both the Listener and HTTPRoute have specified hostnames, any\nHTTPRoute hostnames that do not match the Listener hostname MUST be\nignored. For example, if a Listener specified `*.example.com`, and the\nHTTPRoute specified `test.example.com` and `test.example.net`,\n`test.example.net` must not be considered for a match.\n\nIf both the Listener and HTTPRoute have specified hostnames, and none\nmatch with the criteria above, then the HTTPRoute is not accepted. The\nimplementation must raise an 'Accepted' Condition with a status of\n`False` in the corresponding RouteParentStatus.\n\nIn the event that multiple HTTPRoutes specify intersecting hostnames (e.g.\noverlapping wildcard matching and exact matching hostnames), precedence must\nbe given to rules from the HTTPRoute with the largest number of:\n\n* Characters in a matching non-wildcard hostname.\n* Characters in a matching hostname.\n\nIf ties exist across multiple Routes, the matching precedence rules for\nHTTPRouteMatches takes over.\n\nSupport: Core";
          type = (types.nullOr (types.listOf (types.withMaxLength 253 (types.withMinLength 1 types.str))));
        };
        "parentRefs" = mkOption {
          description = "ParentRefs references the resources (usually Gateways) that a Route wants\nto be attached to. Note that the referenced parent resource needs to\nallow this for the attachment to be complete. For Gateways, that means\nthe Gateway needs to allow attachment from Routes of this kind and\nnamespace. For Services, that means the Service must either be in the same\nnamespace for a \"producer\" route, or the mesh implementation must support\nand allow \"consumer\" routes for the referenced Service. ReferenceGrant is\nnot applicable for governing ParentRefs to Services - it is not possible to\ncreate a \"producer\" route for a Service in a different namespace from the\nRoute.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nThis API may be extended in the future to support additional kinds of parent\nresources.\n\nParentRefs must be _distinct_. This means either that:\n\n* They select different objects.  If this is the case, then parentRef\n  entries are distinct. In terms of fields, this means that the\n  multi-part key defined by `group`, `kind`, `namespace`, and `name` must\n  be unique across all parentRef entries in the Route.\n* They do not select different objects, but for each optional field used,\n  each ParentRef that selects the same object must set the same set of\n  optional fields to different values. If one ParentRef sets a\n  combination of optional fields, all must set the same combination.\n\nSome examples:\n\n* If one ParentRef sets `sectionName`, all ParentRefs referencing the\n  same object must also set `sectionName`.\n* If one ParentRef sets `port`, all ParentRefs referencing the same\n  object must also set `port`.\n* If one ParentRef sets `sectionName` and `port`, all ParentRefs\n  referencing the same object must also set `sectionName` and `port`.\n\nIt is possible to separately reference multiple distinct objects that may\nbe collapsed by an implementation. For example, some implementations may\nchoose to merge compatible Gateway Listeners together. If that is the\ncase, the list of routes attached to those resources should also be\nmerged.\n\nNote that for ParentRefs that cross namespace boundaries, there are specific\nrules. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example,\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable other kinds of cross-namespace reference.\n\n<gateway:experimental:description>\nParentRefs from a Route to a Service in the same namespace are \"producer\"\nroutes, which apply default routing rules to inbound connections from\nany namespace to the Service.\n\nParentRefs from a Route to a Service in a different namespace are\n\"consumer\" routes, and these routing rules are only applied to outbound\nconnections originating from the same namespace as the Route, for which\nthe intended destination of the connections are a Service targeted as a\nParentRef of the Route.\n</gateway:experimental:description>\n<gateway:standard:validation:XValidation:message=\"sectionName must be specified when parentRefs includes 2 or more references to the same parent\",rule=\"self.all(p1, self.all(p2, p1.group == p2.group && p1.kind == p2.kind && p1.name == p2.name && (((!has(p1.__namespace__) || p1.__namespace__ == '') && (!has(p2.__namespace__) || p2.__namespace__ == '')) || (has(p1.__namespace__) && has(p2.__namespace__) && p1.__namespace__ == p2.__namespace__ )) ? ((!has(p1.sectionName) || p1.sectionName == '') == (!has(p2.sectionName) || p2.sectionName == '')) : true))\">\n<gateway:standard:validation:XValidation:message=\"sectionName must be unique when parentRefs includes 2 or more references to the same parent\",rule=\"self.all(p1, self.exists_one(p2, p1.group == p2.group && p1.kind == p2.kind && p1.name == p2.name && (((!has(p1.__namespace__) || p1.__namespace__ == '') && (!has(p2.__namespace__) || p2.__namespace__ == '')) || (has(p1.__namespace__) && has(p2.__namespace__) && p1.__namespace__ == p2.__namespace__ )) && (((!has(p1.sectionName) || p1.sectionName == '') && (!has(p2.sectionName) || p2.sectionName == '')) || (has(p1.sectionName) && has(p2.sectionName) && p1.sectionName == p2.sectionName))))\">\n<gateway:experimental:validation:XValidation:message=\"sectionName or port must be specified when parentRefs includes 2 or more references to the same parent\",rule=\"self.all(p1, self.all(p2, p1.group == p2.group && p1.kind == p2.kind && p1.name == p2.name && (((!has(p1.__namespace__) || p1.__namespace__ == '') && (!has(p2.__namespace__) || p2.__namespace__ == '')) || (has(p1.__namespace__) && has(p2.__namespace__) && p1.__namespace__ == p2.__namespace__)) ? ((!has(p1.sectionName) || p1.sectionName == '') == (!has(p2.sectionName) || p2.sectionName == '') && (!has(p1.port) || p1.port == 0) == (!has(p2.port) || p2.port == 0)): true))\">\n<gateway:experimental:validation:XValidation:message=\"sectionName or port must be unique when parentRefs includes 2 or more references to the same parent\",rule=\"self.all(p1, self.exists_one(p2, p1.group == p2.group && p1.kind == p2.kind && p1.name == p2.name && (((!has(p1.__namespace__) || p1.__namespace__ == '') && (!has(p2.__namespace__) || p2.__namespace__ == '')) || (has(p1.__namespace__) && has(p2.__namespace__) && p1.__namespace__ == p2.__namespace__ )) && (((!has(p1.sectionName) || p1.sectionName == '') && (!has(p2.sectionName) || p2.sectionName == '')) || ( has(p1.sectionName) && has(p2.sectionName) && p1.sectionName == p2.sectionName)) && (((!has(p1.port) || p1.port == 0) && (!has(p2.port) || p2.port == 0)) || (has(p1.port) && has(p2.port) && p1.port == p2.port))))\">";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecParentRefs"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "rules" = mkOption {
          description = "Rules are a list of HTTP matchers, filters and actions.\n\n<gateway:experimental:validation:XValidation:message=\"Rule name must be unique within the route\",rule=\"self.all(l1, !has(l1.name) || self.exists_one(l2, has(l2.name) && l1.name == l2.name))\">";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRules"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "useDefaultGateways" = mkOption {
          description = "UseDefaultGateways indicates the default Gateway scope to use for this\nRoute. If unset (the default) or set to None, the Route will not be\nattached to any default Gateway; if set, it will be attached to any\ndefault Gateway supporting the named scope, subject to the usual rules\nabout which Routes a Gateway is allowed to claim.\n\nThink carefully before using this functionality! The set of default\nGateways supporting the requested scope can change over time without\nany notice to the Route author, and in many situations it will not be\nappropriate to request a default Gateway for a given Route -- for\nexample, a Route with specific security requirements should almost\ncertainly not use a default Gateway.\n\n<gateway:experimental>";
          type = (
            types.nullOr (
              types.enum [
                "All"
                "None"
              ]
            )
          );
        };
      };

      config = {
        "hostnames" = mkOverride 1002 null;
        "parentRefs" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
        "useDefaultGateways" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecParentRefs" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent.\nWhen unspecified, \"gateway.networking.k8s.io\" is inferred.\nTo set the core API group (such as for a \"Service\" kind referent),\nGroup must be explicitly set to \"\" (empty string).\n\nSupport: Core";
          type = (types.nullOr (types.withMaxLength 253 types.str));
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent.\n\nThere are two kinds of parent resources with \"Core\" support:\n\n* Gateway (Gateway conformance profile)\n* Service (Mesh conformance profile, ClusterIP Services only)\n\nSupport for other resources is Implementation-Specific.";
          type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
        };
        "name" = mkOption {
          description = "Name is the name of the referent.\n\nSupport: Core";
          type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the referent. When unspecified, this refers\nto the local namespace of the Route.\n\nNote that there are specific rules for ParentRefs which cross namespace\nboundaries. Cross-namespace references are only valid if they are explicitly\nallowed by something in the namespace they are referring to. For example:\nGateway has the AllowedRoutes field, and ReferenceGrant provides a\ngeneric way to enable any other kind of cross-namespace reference.\n\n<gateway:experimental:description>\nParentRefs from a Route to a Service in the same namespace are \"producer\"\nroutes, which apply default routing rules to inbound connections from\nany namespace to the Service.\n\nParentRefs from a Route to a Service in a different namespace are\n\"consumer\" routes, and these routing rules are only applied to outbound\nconnections originating from the same namespace as the Route, for which\nthe intended destination of the connections are a Service targeted as a\nParentRef of the Route.\n</gateway:experimental:description>\n\nSupport: Core";
          type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
        };
        "port" = mkOption {
          description = "Port is the network port this Route targets. It can be interpreted\ndifferently based on the type of parent resource.\n\nWhen the parent resource is a Gateway, this targets all listeners\nlistening on the specified port that also support this kind of Route(and\nselect this Route). It's not recommended to set `Port` unless the\nnetworking behaviors specified in a Route must apply to a specific port\nas opposed to a listener(s) whose port(s) may be changed. When both Port\nand SectionName are specified, the name and port of the selected listener\nmust match both specified values.\n\n<gateway:experimental:description>\nWhen the parent resource is a Service, this targets a specific port in the\nService spec. When both Port (experimental) and SectionName are specified,\nthe name and port of the selected port must match both specified values.\n</gateway:experimental:description>\n\nImplementations MAY choose to support other parent resources.\nImplementations supporting other types of parent resources MUST clearly\ndocument how/if Port is interpreted.\n\nFor the purpose of status, an attachment is considered successful as\nlong as the parent resource accepts it partially. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment\nfrom the referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route,\nthe Route MUST be considered detached from the Gateway.\n\nSupport: Extended";
          type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 1 types.int)));
        };
        "sectionName" = mkOption {
          description = "SectionName is the name of a section within the target resource. In the\nfollowing resources, SectionName is interpreted as the following:\n\n* Gateway: Listener name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n* Service: Port name. When both Port (experimental) and SectionName\nare specified, the name and port of the selected listener must match\nboth specified values.\n\nImplementations MAY choose to support attaching Routes to other resources.\nIf that is the case, they MUST clearly document how SectionName is\ninterpreted.\n\nWhen unspecified (empty string), this will reference the entire resource.\nFor the purpose of status, an attachment is considered successful if at\nleast one section in the parent resource accepts it. For example, Gateway\nlisteners can restrict which Routes can attach to them by Route kind,\nnamespace, or hostname. If 1 of 2 Gateway listeners accept attachment from\nthe referencing Route, the Route MUST be considered successfully\nattached. If no Gateway listeners accept attachment from this Route, the\nRoute MUST be considered detached from the Gateway.\n\nSupport: Core";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sectionName" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRules" = {

      options = {
        "backendRefs" = mkOption {
          description = "BackendRefs defines the backend(s) where matching requests should be\nsent.\n\nFailure behavior here depends on how many BackendRefs are specified and\nhow many are invalid.\n\nIf *all* entries in BackendRefs are invalid, and there are also no filters\nspecified in this route rule, *all* traffic which matches this rule MUST\nreceive a 500 status code.\n\nSee the HTTPBackendRef definition for the rules about what makes a single\nHTTPBackendRef invalid.\n\nWhen a HTTPBackendRef is invalid, 500 status codes MUST be returned for\nrequests that would have otherwise been routed to an invalid backend. If\nmultiple backends are specified, and some are invalid, the proportion of\nrequests that would otherwise have been routed to an invalid backend\nMUST receive a 500 status code.\n\nFor example, if two backends are specified with equal weights, and one is\ninvalid, 50 percent of traffic must receive a 500. Implementations may\nchoose how that 50 percent is determined.\n\nWhen a HTTPBackendRef refers to a Service that has no ready endpoints,\nimplementations SHOULD return a 503 for requests to that backend instead.\nIf an implementation chooses to do this, all of the above rules for 500 responses\nMUST also apply for responses that return a 503.\n\nSupport: Core for Kubernetes Service\n\nSupport: Extended for Kubernetes ServiceImport\n\nSupport: Implementation-specific for any other resource\n\nSupport for weight: Core";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefs"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "filters" = mkOption {
          description = "Filters define the filters that are applied to requests that match\nthis rule.\n\nWherever possible, implementations SHOULD implement filters in the order\nthey are specified.\n\nImplementations MAY choose to implement this ordering strictly, rejecting\nany combination or order of filters that cannot be supported. If implementations\nchoose a strict interpretation of filter ordering, they MUST clearly document\nthat behavior.\n\nTo reject an invalid combination or order of filters, implementations SHOULD\nconsider the Route Rules with this configuration invalid. If all Route Rules\nin a Route are invalid, the entire Route would be considered invalid. If only\na portion of Route Rules are invalid, implementations MUST set the\n\"PartiallyInvalid\" condition for the Route.\n\nConformance-levels at this level are defined based on the type of filter:\n\n- ALL core filters MUST be supported by all implementations.\n- Implementers are encouraged to support extended filters.\n- Implementation-specific custom filters have no API guarantees across\n  implementations.\n\nSpecifying the same filter multiple times is not supported unless explicitly\nindicated in the filter.\n\nAll filters are expected to be compatible with each other except for the\nURLRewrite and RequestRedirect filters, which may not be combined. If an\nimplementation cannot support other combinations of filters, they must clearly\ndocument that limitation. In cases where incompatible or unsupported\nfilters are specified and cause the `Accepted` condition to be set to status\n`False`, implementations may use the `IncompatibleFilters` reason to specify\nthis configuration error.\n\nSupport: Core";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFilters")
            )
          );
        };
        "matches" = mkOption {
          description = "Matches define conditions used for matching the rule against incoming\nHTTP requests. Each match is independent, i.e. this rule will be matched\nif **any** one of the matches is satisfied.\n\nFor example, take the following matches configuration:\n\n```\nmatches:\n- path:\n    value: \"/foo\"\n  headers:\n  - name: \"version\"\n    value: \"v2\"\n- path:\n    value: \"/v2/foo\"\n```\n\nFor a request to match against this rule, a request must satisfy\nEITHER of the two conditions:\n\n- path prefixed with `/foo` AND contains the header `version: v2`\n- path prefix of `/v2/foo`\n\nSee the documentation for HTTPRouteMatch on how to specify multiple\nmatch conditions that should be ANDed together.\n\nIf no matches are specified, the default is a prefix\npath match on \"/\", which has the effect of matching every\nHTTP request.\n\nProxy or Load Balancer routing configuration generated from HTTPRoutes\nMUST prioritize matches based on the following criteria, continuing on\nties. Across all rules specified on applicable Routes, precedence must be\ngiven to the match having:\n\n* \"Exact\" path match.\n* \"Prefix\" path match with largest number of characters.\n* Method match.\n* Largest number of header matches.\n* Largest number of query param matches.\n\nNote: The precedence of RegularExpression path matches are implementation-specific.\n\nIf ties still exist across multiple Routes, matching precedence MUST be\ndetermined in order of the following criteria, continuing on ties:\n\n* The oldest Route based on creation timestamp.\n* The Route appearing first in alphabetical order by\n  \"{namespace}/{name}\".\n\nIf ties still exist within an HTTPRoute, matching precedence MUST be granted\nto the FIRST matching rule (in list order) with a match meeting the above\ncriteria.\n\nWhen no rules matching a request have been successfully attached to the\nparent a request is coming from, a HTTP 404 status code MUST be returned.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesMatches")
            )
          );
        };
        "name" = mkOption {
          description = "Name is the name of the route rule. This name MUST be unique within a Route if it is set.\n\nSupport: Extended";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
        "retry" = mkOption {
          description = "Retry defines the configuration for when to retry an HTTP request.\n\nSupport: Extended\n\n<gateway:experimental>";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesRetry")
          );
        };
        "sessionPersistence" = mkOption {
          description = "SessionPersistence defines and configures session persistence\nfor the route rule.\n\nSupport: Extended\n\n<gateway:experimental>";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesSessionPersistence"
            )
          );
        };
        "timeouts" = mkOption {
          description = "Timeouts defines the timeouts that can be configured for an HTTP request.\n\nSupport: Extended";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesTimeouts")
          );
        };
      };

      config = {
        "backendRefs" = mkOverride 1002 null;
        "filters" = mkOverride 1002 null;
        "matches" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "retry" = mkOverride 1002 null;
        "sessionPersistence" = mkOverride 1002 null;
        "timeouts" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefs" = {

      options = {
        "filters" = mkOption {
          description = "Filters defined at this level should be executed if and only if the\nrequest is being forwarded to the backend defined here.\n\nSupport: Implementation-specific (For broader support of filters, use the\nFilters field in HTTPRouteRule.)";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFilters"
              )
            )
          );
        };
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = (types.nullOr (types.withMaxLength 253 types.str));
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 1 types.int)));
        };
        "weight" = mkOption {
          description = "Weight specifies the proportion of requests forwarded to the referenced\nbackend. This is computed as weight/(sum of all weights in this\nBackendRefs list). For non-zero values, there may be some epsilon from\nthe exact proportion defined here depending on the precision an\nimplementation supports. Weight is not a percentage and the sum of\nweights does not need to equal 100.\n\nIf only one backend is specified and it has a weight greater than 0, 100%\nof the traffic is forwarded to that backend. If weight is set to 0, no\ntraffic should be forwarded for this entry. If unspecified, weight\ndefaults to 1.\n\nSupport for this field varies based on the context where used.";
          type = (types.nullOr (types.withMaximum 1000000 (types.withMinimum 0 types.int)));
        };
      };

      config = {
        "filters" = mkOverride 1002 null;
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "weight" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFilters" = {

      options = {
        "cors" = mkOption {
          description = "CORS defines a schema for a filter that responds to the\ncross-origin request based on HTTP response header.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersCors"
            )
          );
        };
        "extensionRef" = mkOption {
          description = "ExtensionRef is an optional, implementation-specific extension to the\n\"filter\" behavior.  For example, resource \"myroutefilter\" in group\n\"networking.example.net\"). ExtensionRef MUST NOT be used for core and\nextended filters.\n\nThis filter can be used multiple times within the same rule.\n\nSupport: Implementation-specific";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExtensionRef"
            )
          );
        };
        "externalAuth" = mkOption {
          description = "ExternalAuth configures settings related to sending request details\nto an external auth service. The external service MUST authenticate\nthe request, and MAY authorize the request as well.\n\nIf there is any problem communicating with the external service,\nthis filter MUST fail closed.\n\nSupport: Extended\n\n<gateway:experimental>";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExternalAuth"
            )
          );
        };
        "requestHeaderModifier" = mkOption {
          description = "RequestHeaderModifier defines a schema for a filter that modifies request\nheaders.\n\nSupport: Core";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestHeaderModifier"
            )
          );
        };
        "requestMirror" = mkOption {
          description = "RequestMirror defines a schema for a filter that mirrors requests.\nRequests are sent to the specified destination, but responses from\nthat destination are ignored.\n\nThis filter can be used multiple times within the same rule. Note that\nnot all implementations will be able to support mirroring to multiple\nbackends.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestMirror"
            )
          );
        };
        "requestRedirect" = mkOption {
          description = "RequestRedirect defines a schema for a filter that responds to the\nrequest with an HTTP redirection.\n\nSupport: Core";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestRedirect"
            )
          );
        };
        "responseHeaderModifier" = mkOption {
          description = "ResponseHeaderModifier defines a schema for a filter that modifies response\nheaders.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersResponseHeaderModifier"
            )
          );
        };
        "type" = mkOption {
          description = "Type identifies the type of filter to apply. As with other API fields,\ntypes are classified into three conformance levels:\n\n- Core: Filter types and their corresponding configuration defined by\n  \"Support: Core\" in this package, e.g. \"RequestHeaderModifier\". All\n  implementations must support core filters.\n\n- Extended: Filter types and their corresponding configuration defined by\n  \"Support: Extended\" in this package, e.g. \"RequestMirror\". Implementers\n  are encouraged to support extended filters.\n\n- Implementation-specific: Filters that are defined and supported by\n  specific vendors.\n  In the future, filters showing convergence in behavior across multiple\n  implementations will be considered for inclusion in extended or core\n  conformance levels. Filter-specific configuration for such filters\n  is specified using the ExtensionRef field. `Type` should be set to\n  \"ExtensionRef\" for custom filters.\n\nImplementers are encouraged to define custom implementation types to\nextend the core API with implementation-specific behavior.\n\nIf a reference to a custom filter type cannot be resolved, the filter\nMUST NOT be skipped. Instead, requests that would have been processed by\nthat filter MUST receive a HTTP error response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\n<gateway:experimental:validation:Enum=RequestHeaderModifier;ResponseHeaderModifier;RequestMirror;RequestRedirect;URLRewrite;ExtensionRef;CORS;ExternalAuth>";
          type = (
            types.enum [
              "RequestHeaderModifier"
              "ResponseHeaderModifier"
              "RequestMirror"
              "RequestRedirect"
              "URLRewrite"
              "ExtensionRef"
              "CORS"
            ]
          );
        };
        "urlRewrite" = mkOption {
          description = "URLRewrite defines a schema for a filter that modifies a request during forwarding.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersUrlRewrite"
            )
          );
        };
      };

      config = {
        "cors" = mkOverride 1002 null;
        "extensionRef" = mkOverride 1002 null;
        "externalAuth" = mkOverride 1002 null;
        "requestHeaderModifier" = mkOverride 1002 null;
        "requestMirror" = mkOverride 1002 null;
        "requestRedirect" = mkOverride 1002 null;
        "responseHeaderModifier" = mkOverride 1002 null;
        "urlRewrite" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersCors" = {

      options = {
        "allowCredentials" = mkOption {
          description = "AllowCredentials indicates whether the actual cross-origin request allows\nto include credentials.\n\nWhen set to true, the gateway will include the `Access-Control-Allow-Credentials`\nresponse header with value true (case-sensitive).\n\nWhen set to false or omitted the gateway will omit the header\n`Access-Control-Allow-Credentials` entirely (this is the standard CORS\nbehavior).\n\nSupport: Extended";
          type = (types.nullOr types.bool);
        };
        "allowHeaders" = mkOption {
          description = "AllowHeaders indicates which HTTP request headers are supported for\naccessing the requested resource.\n\nHeader names are not case-sensitive.\n\nMultiple header names in the value of the `Access-Control-Allow-Headers`\nresponse header are separated by a comma (\",\").\n\nWhen the `allowHeaders` field is configured with one or more headers, the\ngateway must return the `Access-Control-Allow-Headers` response header\nwhich value is present in the `allowHeaders` field.\n\nIf any header name in the `Access-Control-Request-Headers` request header\nis not included in the list of header names specified by the response\nheader `Access-Control-Allow-Headers`, it will present an error on the\nclient side.\n\nIf any header name in the `Access-Control-Allow-Headers` response header\ndoes not recognize by the client, it will also occur an error on the\nclient side.\n\nA wildcard indicates that the requests with all HTTP headers are allowed.\n\nIf the configuration contains the wildcard `*` in `allowHeaders` and\n`allowCredentials` is set to `false`, the `Access-Control-Allow-Headers`\nresponse header may either contain the wildcard `*` or echo the value\nof the `Access-Control-Request-Headers` request header.\n\nIf the configuration contains the wildcard `*` in `allowHeaders` and\n`allowCredentials` is set to `true`, the gateway must not return `*`\nin the `Access-Control-Allow-Headers` response header. Instead, it must\nreturn one or more header names matching the value of the\n`Access-Control-Request-Headers` request header.\nIf the `Access-Control-Request-Headers` header is not present in the\nrequest, the gateway must omit the `Access-Control-Allow-Headers`\nresponse header.\n\nSupport: Extended";
          type = (types.nullOr (types.listOf (types.withMaxLength 256 (types.withMinLength 1 types.str))));
        };
        "allowMethods" = mkOption {
          description = "AllowMethods indicates which HTTP methods are supported for accessing the\nrequested resource.\n\nValid values are any method defined by RFC9110, along with the special\nvalue `*`, which represents all HTTP methods are allowed.\n\nMethod names are case-sensitive, so these values are also case-sensitive.\n(See https://www.rfc-editor.org/rfc/rfc2616#section-5.1.1)\n\nMultiple method names in the value of the `Access-Control-Allow-Methods`\nresponse header are separated by a comma (\",\").\n\nA CORS-safelisted method is a method that is `GET`, `HEAD`, or `POST`.\n(See https://fetch.spec.whatwg.org/#cors-safelisted-method) The\nCORS-safelisted methods are always allowed, regardless of whether they\nare specified in the `allowMethods` field.\n\nWhen the `allowMethods` field is configured with one or more methods, the\ngateway must return the `Access-Control-Allow-Methods` response header\nwhich value is present in the `allowMethods` field.\n\nIf the HTTP method of the `Access-Control-Request-Method` request header\nis not included in the list of methods specified by the response header\n`Access-Control-Allow-Methods`, it will present an error on the client\nside.\n\nIf the configuration contains the wildcard `*` in `allowMethods` and\n`allowCredentials` is set to `false`, the `Access-Control-Allow-Methods`\nresponse header may either contain the wildcard `*` or echo the value\nof the `Access-Control-Request-Method` request header.\n\nIf the configuration contains the wildcard `*` in `allowMethods` and\n`allowCredentials` is set to `true`, the gateway must not return `*`\nin the `Access-Control-Allow-Methods` response header. Instead, it must\nreturn a single HTTP method matching the value of the\n`Access-Control-Request-Method` request header.\nIf the `Access-Control-Request-Method` header is not present in the request,\nthe gateway must omit the `Access-Control-Allow-Methods` response header.\n\nSupport: Extended";
          type = (
            types.nullOr (
              types.listOf (
                types.enum [
                  "GET"
                  "HEAD"
                  "POST"
                  "PUT"
                  "DELETE"
                  "CONNECT"
                  "OPTIONS"
                  "TRACE"
                  "PATCH"
                  "*"
                ]
              )
            )
          );
        };
        "allowOrigins" = mkOption {
          description = "AllowOrigins indicates whether the response can be shared with requested\nresource from the given `Origin`.\n\nThe `Origin` consists of a scheme and a host, with an optional port, and\ntakes the form `<scheme>://<host>(:<port>)`.\n\nValid values for scheme are: `http` and `https`.\n\nValid values for port are any integer between 1 and 65535 (the list of\navailable TCP/UDP ports). Note that, if not included, port `80` is\nassumed for `http` scheme origins, and port `443` is assumed for `https`\norigins. This may affect origin matching.\n\nThe host part of the origin may contain the wildcard character `*`. These\nwildcard characters behave as follows:\n\n* `*` is a greedy match to the _left_, including any number of\n  DNS labels to the left of its position. This also means that\n  `*` will include any number of period `.` characters to the\n  left of its position.\n* A wildcard by itself matches all hosts.\n\nAn origin value that includes _only_ the `*` character indicates requests\nfrom all `Origin`s are allowed.\n\nWhen the `allowOrigins` field is configured with multiple origins, it\nmeans the server supports clients from multiple origins. If the request\n`Origin` matches the configured allowed origins, the gateway must return\nthe given `Origin` and sets value of the header\n`Access-Control-Allow-Origin` same as the `Origin` header provided by the\nclient.\n\nThe status code of a successful response to a \"preflight\" request is\nalways an OK status (i.e., 204 or 200).\n\nIf the request `Origin` does not match the configured allowed origins,\nthe gateway returns 204/200 response but doesn't set the relevant\ncross-origin response headers. Alternatively, the gateway responds with\n403 status to the \"preflight\" request is denied, coupled with omitting\nthe CORS headers. The cross-origin request fails on the client side.\nTherefore, the client doesn't attempt the actual cross-origin request.\n\nConversely, if the request `Origin` matches one of the configured\nallowed origins, the gateway sets the response header\n`Access-Control-Allow-Origin` to the same value as the `Origin`\nheader provided by the client.\n\nIf the configuration contains the wildcard `*` in `allowOrigins` and\n`allowCredentials` is set to `false`, the `Access-Control-Allow-Origin`\nresponse header may either contain the wildcard `*` or echo the value\nof the `Origin` request header.\n\nIf the configuration contains the wildcard `*` in `allowOrigins` and\n`allowCredentials` is set to `true`, the gateway must not return `*`\nin the `Access-Control-Allow-Origin` response header. Instead, it must\nreturn a single origin matching the value of the `Origin` request header.\n\nSupport: Extended";
          type = (types.nullOr (types.listOf (types.withMaxLength 253 (types.withMinLength 1 types.str))));
        };
        "exposeHeaders" = mkOption {
          description = "ExposeHeaders indicates which HTTP response headers can be exposed\nto client-side scripts in response to a cross-origin request.\n\nA CORS-safelisted response header is an HTTP header in a CORS response\nthat it is considered safe to expose to the client scripts.\nThe CORS-safelisted response headers include the following headers:\n`Cache-Control`\n`Content-Language`\n`Content-Length`\n`Content-Type`\n`Expires`\n`Last-Modified`\n`Pragma`\n(See https://fetch.spec.whatwg.org/#cors-safelisted-response-header-name)\nThe CORS-safelisted response headers are exposed to client by default.\n\nWhen an HTTP header name is specified using the `exposeHeaders` field,\nthis additional header will be exposed as part of the response to the\nclient.\n\nHeader names are not case-sensitive.\n\nMultiple header names in the value of the `Access-Control-Expose-Headers`\nresponse header are separated by a comma (\",\").\n\nA wildcard indicates that the responses with all HTTP headers are exposed\nto clients.\n\nIf the configuration contains the wildcard `*` in `exposeHeaders` and\n`allowCredentials` is set to `false`, the `Access-Control-Expose-Headers`\nresponse header can contain the wildcard `*`.\n\nIf the configuration contains the wildcard `*` in `exposeHeaders` and\n`allowCredentials` is set to `true`, the gateway cannot use the `*`\nin the `Access-Control-Expose-Headers` response header.\n\nSupport: Extended";
          type = (types.nullOr (types.listOf (types.withMaxLength 256 (types.withMinLength 1 types.str))));
        };
        "maxAge" = mkOption {
          description = "MaxAge indicates the duration (in seconds) for the client to cache the\nresults of a \"preflight\" request.\n\nThe information provided by the `Access-Control-Allow-Methods` and\n`Access-Control-Allow-Headers` response headers can be cached by the\nclient until the time specified by `Access-Control-Max-Age` elapses.\n\nThe default value of `Access-Control-Max-Age` response header is 5\n(seconds).\n\nWhen the `MaxAge` field is unspecified, the gateway sets the response\nheader \"Access-Control-Max-Age: 5\" by default.";
          type = (types.nullOr (types.withMinimum 1 types.int));
        };
      };

      config = {
        "allowCredentials" = mkOverride 1002 null;
        "allowHeaders" = mkOverride 1002 null;
        "allowMethods" = mkOverride 1002 null;
        "allowOrigins" = mkOverride 1002 null;
        "exposeHeaders" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExtensionRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = (types.withMaxLength 253 types.str);
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\".";
          type = (types.withMaxLength 63 (types.withMinLength 1 types.str));
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExternalAuth" = {

      options = {
        "backendRef" = mkOption {
          description = "BackendRef is a reference to a backend to send authorization\nrequests to.\n\nThe backend must speak the selected protocol (GRPC or HTTP) on the\nreferenced port.\n\nIf the backend service requires TLS, use BackendTLSPolicy to tell the\nimplementation to supply the TLS details to be used to connect to that\nbackend.";
          type = (
            submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExternalAuthBackendRef"
          );
        };
        "forwardBody" = mkOption {
          description = "ForwardBody controls if requests to the authorization server should include\nthe body of the client request; and if so, how big that body is allowed\nto be.\n\nIt is expected that implementations will buffer the request body up to\n`forwardBody.maxSize` bytes. Bodies over that size must be rejected with a\n4xx series error (413 or 403 are common examples), and fail processing\nof the filter.\n\nIf unset, or `forwardBody.maxSize` is set to `0`, then the body will not\nbe forwarded.\n\nFeature Name: HTTPRouteExternalAuthForwardBody";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExternalAuthForwardBody"
            )
          );
        };
        "grpc" = mkOption {
          description = "GRPCAuthConfig contains configuration for communication with ext_authz\nprotocol-speaking backends.\n\nIf unset, implementations must assume the default behavior for each\nincluded field is intended.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExternalAuthGrpc"
            )
          );
        };
        "http" = mkOption {
          description = "HTTPAuthConfig contains configuration for communication with HTTP-speaking\nbackends.\n\nIf unset, implementations must assume the default behavior for each\nincluded field is intended.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExternalAuthHttp"
            )
          );
        };
        "protocol" = mkOption {
          description = "ExternalAuthProtocol describes which protocol to use when communicating with an\next_authz authorization server.\n\nWhen this is set to GRPC, each backend must use the Envoy ext_authz protocol\non the port specified in `backendRefs`. Requests and responses are defined\nin the protobufs explained at:\nhttps://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto\n\nWhen this is set to HTTP, each backend must respond with a `200` status\ncode in on a successful authorization. Any other code is considered\nan authorization failure.\n\nFeature Names:\nGRPC Support - HTTPRouteExternalAuthGRPC\nHTTP Support - HTTPRouteExternalAuthHTTP";
          type = (
            types.enum [
              "HTTP"
              "GRPC"
            ]
          );
        };
      };

      config = {
        "forwardBody" = mkOverride 1002 null;
        "grpc" = mkOverride 1002 null;
        "http" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExternalAuthBackendRef" =
      {

        options = {
          "group" = mkOption {
            description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
            type = (types.nullOr (types.withMaxLength 253 types.str));
          };
          "kind" = mkOption {
            description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
            type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
          };
          "name" = mkOption {
            description = "Name is the name of the referent.";
            type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
          };
          "namespace" = mkOption {
            description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
            type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
          };
          "port" = mkOption {
            description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
            type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 1 types.int)));
          };
        };

        config = {
          "group" = mkOverride 1002 null;
          "kind" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
          "port" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExternalAuthForwardBody" =
      {

        options = {
          "maxSize" = mkOption {
            description = "MaxSize specifies how large in bytes the largest body that will be buffered\nand sent to the authorization server. If the body size is larger than\n`maxSize`, then the body sent to the authorization server must be\ntruncated to `maxSize` bytes.\n\nExperimental note: This behavior needs to be checked against\nvarious dataplanes; it may need to be changed.\nSee https://github.com/kubernetes-sigs/gateway-api/pull/4001#discussion_r2291405746\nfor more.\n\nIf 0, the body will not be sent to the authorization server.";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "maxSize" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExternalAuthGrpc" =
      {

        options = {
          "allowedHeaders" = mkOption {
            description = "AllowedRequestHeaders specifies what headers from the client request\nwill be sent to the authorization server.\n\nIf this list is empty, then all headers must be sent.\n\nIf the list has entries, only those entries must be sent.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "allowedHeaders" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersExternalAuthHttp" =
      {

        options = {
          "allowedHeaders" = mkOption {
            description = "AllowedRequestHeaders specifies what additional headers from the client request\nwill be sent to the authorization server.\n\nThe following headers must always be sent to the authorization server,\nregardless of this setting:\n\n* `Host`\n* `Method`\n* `Path`\n* `Content-Length`\n* `Authorization`\n\nIf this list is empty, then only those headers must be sent.\n\nNote that `Content-Length` has a special behavior, in that the length\nsent must be correct for the actual request to the external authorization\nserver - that is, it must reflect the actual number of bytes sent in the\nbody of the request to the authorization server.\n\nSo if the `forwardBody` stanza is unset, or `forwardBody.maxSize` is set\nto `0`, then `Content-Length` must be `0`. If `forwardBody.maxSize` is set\nto anything other than `0`, then the `Content-Length` of the authorization\nrequest must be set to the actual number of bytes forwarded.";
            type = (types.nullOr (types.listOf types.str));
          };
          "allowedResponseHeaders" = mkOption {
            description = "AllowedResponseHeaders specifies what headers from the authorization response\nwill be copied into the request to the backend.\n\nIf this list is empty, then all headers from the authorization server\nexcept Authority or Host must be copied.";
            type = (types.nullOr (types.listOf types.str));
          };
          "path" = mkOption {
            description = "Path sets the prefix that paths from the client request will have added\nwhen forwarded to the authorization server.\n\nWhen empty or unspecified, no prefix is added.\n\nValid values are the same as the \"value\" regex for path values in the `match`\nstanza, and the validation regex will screen out invalid paths in the same way.\nEven with the validation, implementations MUST sanitize this input before using it\ndirectly.";
            type = (types.nullOr (types.withMaxLength 1024 types.str));
          };
        };

        config = {
          "allowedHeaders" = mkOverride 1002 null;
          "allowedResponseHeaders" = mkOverride 1002 null;
          "path" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestHeaderModifier" =
      {

        options = {
          "add" = mkOption {
            description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestHeaderModifierAdd"
                  "name"
                  [ "name" ]
              )
            );
            apply = attrsToList;
          };
          "remove" = mkOption {
            description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
            type = (types.nullOr (types.listOf types.str));
          };
          "set" = mkOption {
            description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestHeaderModifierSet"
                  "name"
                  [ "name" ]
              )
            );
            apply = attrsToList;
          };
        };

        config = {
          "add" = mkOverride 1002 null;
          "remove" = mkOverride 1002 null;
          "set" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestHeaderModifierAdd" =
      {

        options = {
          "name" = mkOption {
            description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
            type = (types.withMaxLength 256 (types.withMinLength 1 types.str));
          };
          "value" = mkOption {
            description = "Value is the value of HTTP Header to be matched.\n<gateway:experimental:description>\nMust consist of printable US-ASCII characters, optionally separated\nby single tabs or spaces. See: https://tools.ietf.org/html/rfc7230#section-3.2\n</gateway:experimental:description>\n\n<gateway:experimental:validation:Pattern=`^[!-~]+([\\t ]?[!-~]+)*$`>";
            type = (types.withMaxLength 4096 (types.withMinLength 1 types.str));
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestHeaderModifierSet" =
      {

        options = {
          "name" = mkOption {
            description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
            type = (types.withMaxLength 256 (types.withMinLength 1 types.str));
          };
          "value" = mkOption {
            description = "Value is the value of HTTP Header to be matched.\n<gateway:experimental:description>\nMust consist of printable US-ASCII characters, optionally separated\nby single tabs or spaces. See: https://tools.ietf.org/html/rfc7230#section-3.2\n</gateway:experimental:description>\n\n<gateway:experimental:validation:Pattern=`^[!-~]+([\\t ]?[!-~]+)*$`>";
            type = (types.withMaxLength 4096 (types.withMinLength 1 types.str));
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestMirror" = {

      options = {
        "backendRef" = mkOption {
          description = "BackendRef references a resource where mirrored requests are sent.\n\nMirrored requests must be sent only to a single destination endpoint\nwithin this BackendRef, irrespective of how many endpoints are present\nwithin this BackendRef.\n\nIf the referent cannot be found, this BackendRef is invalid and must be\ndropped from the Gateway. The controller must ensure the \"ResolvedRefs\"\ncondition on the Route status is set to `status: False` and not configure\nthis backend in the underlying implementation.\n\nIf there is a cross-namespace reference to an *existing* object\nthat is not allowed by a ReferenceGrant, the controller must ensure the\n\"ResolvedRefs\"  condition on the Route is set to `status: False`,\nwith the \"RefNotPermitted\" reason and not configure this backend in the\nunderlying implementation.\n\nIn either error case, the Message of the `ResolvedRefs` Condition\nshould be used to provide more detail about the problem.\n\nSupport: Extended for Kubernetes Service\n\nSupport: Implementation-specific for any other resource\n\nIf the backend service requires TLS, use BackendTLSPolicy to tell the\nimplementation to supply the TLS details to be used to connect to that\nbackend.";
          type = (
            submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestMirrorBackendRef"
          );
        };
        "fraction" = mkOption {
          description = "Fraction represents the fraction of requests that should be\nmirrored to BackendRef.\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestMirrorFraction"
            )
          );
        };
        "percent" = mkOption {
          description = "Percent represents the percentage of requests that should be\nmirrored to BackendRef. Its minimum value is 0 (indicating 0% of\nrequests) and its maximum value is 100 (indicating 100% of requests).\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = (types.nullOr (types.withMaximum 100 (types.withMinimum 0 types.int)));
        };
      };

      config = {
        "fraction" = mkOverride 1002 null;
        "percent" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestMirrorBackendRef" =
      {

        options = {
          "group" = mkOption {
            description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
            type = (types.nullOr (types.withMaxLength 253 types.str));
          };
          "kind" = mkOption {
            description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
            type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
          };
          "name" = mkOption {
            description = "Name is the name of the referent.";
            type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
          };
          "namespace" = mkOption {
            description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
            type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
          };
          "port" = mkOption {
            description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
            type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 1 types.int)));
          };
        };

        config = {
          "group" = mkOverride 1002 null;
          "kind" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
          "port" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestMirrorFraction" =
      {

        options = {
          "denominator" = mkOption {
            description = "";
            type = (types.nullOr (types.withMinimum 1 types.int));
          };
          "numerator" = mkOption {
            description = "";
            type = (types.withMinimum 0 types.int);
          };
        };

        config = {
          "denominator" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestRedirect" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the hostname to be used in the value of the `Location`\nheader in the response.\nWhen empty, the hostname in the `Host` header of the request is used.\n\nSupport: Core";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
        "path" = mkOption {
          description = "Path defines parameters used to modify the path of the incoming request.\nThe modified path is then used to construct the `Location` header. When\nempty, the request path is used as-is.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestRedirectPath"
            )
          );
        };
        "port" = mkOption {
          description = "Port is the port to be used in the value of the `Location`\nheader in the response.\n\nIf no port is specified, the redirect port MUST be derived using the\nfollowing rules:\n\n* If redirect scheme is not-empty, the redirect port MUST be the well-known\n  port associated with the redirect scheme. Specifically \"http\" to port 80\n  and \"https\" to port 443. If the redirect scheme does not have a\n  well-known port, the listener port of the Gateway SHOULD be used.\n* If redirect scheme is empty, the redirect port MUST be the Gateway\n  Listener port.\n\nImplementations SHOULD NOT add the port number in the 'Location'\nheader in the following cases:\n\n* A Location header that will use HTTP (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 80.\n* A Location header that will use HTTPS (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 443.\n\nSupport: Extended";
          type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 1 types.int)));
        };
        "scheme" = mkOption {
          description = "Scheme is the scheme to be used in the value of the `Location` header in\nthe response. When empty, the scheme of the request is used.\n\nScheme redirects can affect the port of the redirect, for more information,\nrefer to the documentation for the port field of this filter.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Extended";
          type = (
            types.nullOr (
              types.enum [
                "http"
                "https"
              ]
            )
          );
        };
        "statusCode" = mkOption {
          description = "StatusCode is the HTTP status code to be used in response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Core";
          type = (
            types.nullOr (
              types.enum [
                301
                302
                303
                307
                308
              ]
            )
          );
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "statusCode" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersRequestRedirectPath" =
      {

        options = {
          "replaceFullPath" = mkOption {
            description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
            type = (types.nullOr (types.withMaxLength 1024 types.str));
          };
          "replacePrefixMatch" = mkOption {
            description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
            type = (types.nullOr (types.withMaxLength 1024 types.str));
          };
          "type" = mkOption {
            description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
            type = (
              types.enum [
                "ReplaceFullPath"
                "ReplacePrefixMatch"
              ]
            );
          };
        };

        config = {
          "replaceFullPath" = mkOverride 1002 null;
          "replacePrefixMatch" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersResponseHeaderModifier" =
      {

        options = {
          "add" = mkOption {
            description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersResponseHeaderModifierAdd"
                  "name"
                  [ "name" ]
              )
            );
            apply = attrsToList;
          };
          "remove" = mkOption {
            description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
            type = (types.nullOr (types.listOf types.str));
          };
          "set" = mkOption {
            description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
            type = (
              types.nullOr (
                coerceAttrsOfSubmodulesToListByKey
                  "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersResponseHeaderModifierSet"
                  "name"
                  [ "name" ]
              )
            );
            apply = attrsToList;
          };
        };

        config = {
          "add" = mkOverride 1002 null;
          "remove" = mkOverride 1002 null;
          "set" = mkOverride 1002 null;
        };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersResponseHeaderModifierAdd" =
      {

        options = {
          "name" = mkOption {
            description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
            type = (types.withMaxLength 256 (types.withMinLength 1 types.str));
          };
          "value" = mkOption {
            description = "Value is the value of HTTP Header to be matched.\n<gateway:experimental:description>\nMust consist of printable US-ASCII characters, optionally separated\nby single tabs or spaces. See: https://tools.ietf.org/html/rfc7230#section-3.2\n</gateway:experimental:description>\n\n<gateway:experimental:validation:Pattern=`^[!-~]+([\\t ]?[!-~]+)*$`>";
            type = (types.withMaxLength 4096 (types.withMinLength 1 types.str));
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersResponseHeaderModifierSet" =
      {

        options = {
          "name" = mkOption {
            description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
            type = (types.withMaxLength 256 (types.withMinLength 1 types.str));
          };
          "value" = mkOption {
            description = "Value is the value of HTTP Header to be matched.\n<gateway:experimental:description>\nMust consist of printable US-ASCII characters, optionally separated\nby single tabs or spaces. See: https://tools.ietf.org/html/rfc7230#section-3.2\n</gateway:experimental:description>\n\n<gateway:experimental:validation:Pattern=`^[!-~]+([\\t ]?[!-~]+)*$`>";
            type = (types.withMaxLength 4096 (types.withMinLength 1 types.str));
          };
        };

        config = { };

      };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersUrlRewrite" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the value to be used to replace the Host header value during\nforwarding.\n\nSupport: Extended";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
        "path" = mkOption {
          description = "Path defines a path rewrite.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersUrlRewritePath"
            )
          );
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesBackendRefsFiltersUrlRewritePath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = (types.nullOr (types.withMaxLength 1024 types.str));
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = (types.nullOr (types.withMaxLength 1024 types.str));
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = (
            types.enum [
              "ReplaceFullPath"
              "ReplacePrefixMatch"
            ]
          );
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFilters" = {

      options = {
        "cors" = mkOption {
          description = "CORS defines a schema for a filter that responds to the\ncross-origin request based on HTTP response header.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersCors"
            )
          );
        };
        "extensionRef" = mkOption {
          description = "ExtensionRef is an optional, implementation-specific extension to the\n\"filter\" behavior.  For example, resource \"myroutefilter\" in group\n\"networking.example.net\"). ExtensionRef MUST NOT be used for core and\nextended filters.\n\nThis filter can be used multiple times within the same rule.\n\nSupport: Implementation-specific";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExtensionRef"
            )
          );
        };
        "externalAuth" = mkOption {
          description = "ExternalAuth configures settings related to sending request details\nto an external auth service. The external service MUST authenticate\nthe request, and MAY authorize the request as well.\n\nIf there is any problem communicating with the external service,\nthis filter MUST fail closed.\n\nSupport: Extended\n\n<gateway:experimental>";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExternalAuth"
            )
          );
        };
        "requestHeaderModifier" = mkOption {
          description = "RequestHeaderModifier defines a schema for a filter that modifies request\nheaders.\n\nSupport: Core";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestHeaderModifier"
            )
          );
        };
        "requestMirror" = mkOption {
          description = "RequestMirror defines a schema for a filter that mirrors requests.\nRequests are sent to the specified destination, but responses from\nthat destination are ignored.\n\nThis filter can be used multiple times within the same rule. Note that\nnot all implementations will be able to support mirroring to multiple\nbackends.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestMirror"
            )
          );
        };
        "requestRedirect" = mkOption {
          description = "RequestRedirect defines a schema for a filter that responds to the\nrequest with an HTTP redirection.\n\nSupport: Core";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestRedirect"
            )
          );
        };
        "responseHeaderModifier" = mkOption {
          description = "ResponseHeaderModifier defines a schema for a filter that modifies response\nheaders.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersResponseHeaderModifier"
            )
          );
        };
        "type" = mkOption {
          description = "Type identifies the type of filter to apply. As with other API fields,\ntypes are classified into three conformance levels:\n\n- Core: Filter types and their corresponding configuration defined by\n  \"Support: Core\" in this package, e.g. \"RequestHeaderModifier\". All\n  implementations must support core filters.\n\n- Extended: Filter types and their corresponding configuration defined by\n  \"Support: Extended\" in this package, e.g. \"RequestMirror\". Implementers\n  are encouraged to support extended filters.\n\n- Implementation-specific: Filters that are defined and supported by\n  specific vendors.\n  In the future, filters showing convergence in behavior across multiple\n  implementations will be considered for inclusion in extended or core\n  conformance levels. Filter-specific configuration for such filters\n  is specified using the ExtensionRef field. `Type` should be set to\n  \"ExtensionRef\" for custom filters.\n\nImplementers are encouraged to define custom implementation types to\nextend the core API with implementation-specific behavior.\n\nIf a reference to a custom filter type cannot be resolved, the filter\nMUST NOT be skipped. Instead, requests that would have been processed by\nthat filter MUST receive a HTTP error response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\n<gateway:experimental:validation:Enum=RequestHeaderModifier;ResponseHeaderModifier;RequestMirror;RequestRedirect;URLRewrite;ExtensionRef;CORS;ExternalAuth>";
          type = (
            types.enum [
              "RequestHeaderModifier"
              "ResponseHeaderModifier"
              "RequestMirror"
              "RequestRedirect"
              "URLRewrite"
              "ExtensionRef"
              "CORS"
            ]
          );
        };
        "urlRewrite" = mkOption {
          description = "URLRewrite defines a schema for a filter that modifies a request during forwarding.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersUrlRewrite"
            )
          );
        };
      };

      config = {
        "cors" = mkOverride 1002 null;
        "extensionRef" = mkOverride 1002 null;
        "externalAuth" = mkOverride 1002 null;
        "requestHeaderModifier" = mkOverride 1002 null;
        "requestMirror" = mkOverride 1002 null;
        "requestRedirect" = mkOverride 1002 null;
        "responseHeaderModifier" = mkOverride 1002 null;
        "urlRewrite" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersCors" = {

      options = {
        "allowCredentials" = mkOption {
          description = "AllowCredentials indicates whether the actual cross-origin request allows\nto include credentials.\n\nWhen set to true, the gateway will include the `Access-Control-Allow-Credentials`\nresponse header with value true (case-sensitive).\n\nWhen set to false or omitted the gateway will omit the header\n`Access-Control-Allow-Credentials` entirely (this is the standard CORS\nbehavior).\n\nSupport: Extended";
          type = (types.nullOr types.bool);
        };
        "allowHeaders" = mkOption {
          description = "AllowHeaders indicates which HTTP request headers are supported for\naccessing the requested resource.\n\nHeader names are not case-sensitive.\n\nMultiple header names in the value of the `Access-Control-Allow-Headers`\nresponse header are separated by a comma (\",\").\n\nWhen the `allowHeaders` field is configured with one or more headers, the\ngateway must return the `Access-Control-Allow-Headers` response header\nwhich value is present in the `allowHeaders` field.\n\nIf any header name in the `Access-Control-Request-Headers` request header\nis not included in the list of header names specified by the response\nheader `Access-Control-Allow-Headers`, it will present an error on the\nclient side.\n\nIf any header name in the `Access-Control-Allow-Headers` response header\ndoes not recognize by the client, it will also occur an error on the\nclient side.\n\nA wildcard indicates that the requests with all HTTP headers are allowed.\n\nIf the configuration contains the wildcard `*` in `allowHeaders` and\n`allowCredentials` is set to `false`, the `Access-Control-Allow-Headers`\nresponse header may either contain the wildcard `*` or echo the value\nof the `Access-Control-Request-Headers` request header.\n\nIf the configuration contains the wildcard `*` in `allowHeaders` and\n`allowCredentials` is set to `true`, the gateway must not return `*`\nin the `Access-Control-Allow-Headers` response header. Instead, it must\nreturn one or more header names matching the value of the\n`Access-Control-Request-Headers` request header.\nIf the `Access-Control-Request-Headers` header is not present in the\nrequest, the gateway must omit the `Access-Control-Allow-Headers`\nresponse header.\n\nSupport: Extended";
          type = (types.nullOr (types.listOf (types.withMaxLength 256 (types.withMinLength 1 types.str))));
        };
        "allowMethods" = mkOption {
          description = "AllowMethods indicates which HTTP methods are supported for accessing the\nrequested resource.\n\nValid values are any method defined by RFC9110, along with the special\nvalue `*`, which represents all HTTP methods are allowed.\n\nMethod names are case-sensitive, so these values are also case-sensitive.\n(See https://www.rfc-editor.org/rfc/rfc2616#section-5.1.1)\n\nMultiple method names in the value of the `Access-Control-Allow-Methods`\nresponse header are separated by a comma (\",\").\n\nA CORS-safelisted method is a method that is `GET`, `HEAD`, or `POST`.\n(See https://fetch.spec.whatwg.org/#cors-safelisted-method) The\nCORS-safelisted methods are always allowed, regardless of whether they\nare specified in the `allowMethods` field.\n\nWhen the `allowMethods` field is configured with one or more methods, the\ngateway must return the `Access-Control-Allow-Methods` response header\nwhich value is present in the `allowMethods` field.\n\nIf the HTTP method of the `Access-Control-Request-Method` request header\nis not included in the list of methods specified by the response header\n`Access-Control-Allow-Methods`, it will present an error on the client\nside.\n\nIf the configuration contains the wildcard `*` in `allowMethods` and\n`allowCredentials` is set to `false`, the `Access-Control-Allow-Methods`\nresponse header may either contain the wildcard `*` or echo the value\nof the `Access-Control-Request-Method` request header.\n\nIf the configuration contains the wildcard `*` in `allowMethods` and\n`allowCredentials` is set to `true`, the gateway must not return `*`\nin the `Access-Control-Allow-Methods` response header. Instead, it must\nreturn a single HTTP method matching the value of the\n`Access-Control-Request-Method` request header.\nIf the `Access-Control-Request-Method` header is not present in the request,\nthe gateway must omit the `Access-Control-Allow-Methods` response header.\n\nSupport: Extended";
          type = (
            types.nullOr (
              types.listOf (
                types.enum [
                  "GET"
                  "HEAD"
                  "POST"
                  "PUT"
                  "DELETE"
                  "CONNECT"
                  "OPTIONS"
                  "TRACE"
                  "PATCH"
                  "*"
                ]
              )
            )
          );
        };
        "allowOrigins" = mkOption {
          description = "AllowOrigins indicates whether the response can be shared with requested\nresource from the given `Origin`.\n\nThe `Origin` consists of a scheme and a host, with an optional port, and\ntakes the form `<scheme>://<host>(:<port>)`.\n\nValid values for scheme are: `http` and `https`.\n\nValid values for port are any integer between 1 and 65535 (the list of\navailable TCP/UDP ports). Note that, if not included, port `80` is\nassumed for `http` scheme origins, and port `443` is assumed for `https`\norigins. This may affect origin matching.\n\nThe host part of the origin may contain the wildcard character `*`. These\nwildcard characters behave as follows:\n\n* `*` is a greedy match to the _left_, including any number of\n  DNS labels to the left of its position. This also means that\n  `*` will include any number of period `.` characters to the\n  left of its position.\n* A wildcard by itself matches all hosts.\n\nAn origin value that includes _only_ the `*` character indicates requests\nfrom all `Origin`s are allowed.\n\nWhen the `allowOrigins` field is configured with multiple origins, it\nmeans the server supports clients from multiple origins. If the request\n`Origin` matches the configured allowed origins, the gateway must return\nthe given `Origin` and sets value of the header\n`Access-Control-Allow-Origin` same as the `Origin` header provided by the\nclient.\n\nThe status code of a successful response to a \"preflight\" request is\nalways an OK status (i.e., 204 or 200).\n\nIf the request `Origin` does not match the configured allowed origins,\nthe gateway returns 204/200 response but doesn't set the relevant\ncross-origin response headers. Alternatively, the gateway responds with\n403 status to the \"preflight\" request is denied, coupled with omitting\nthe CORS headers. The cross-origin request fails on the client side.\nTherefore, the client doesn't attempt the actual cross-origin request.\n\nConversely, if the request `Origin` matches one of the configured\nallowed origins, the gateway sets the response header\n`Access-Control-Allow-Origin` to the same value as the `Origin`\nheader provided by the client.\n\nIf the configuration contains the wildcard `*` in `allowOrigins` and\n`allowCredentials` is set to `false`, the `Access-Control-Allow-Origin`\nresponse header may either contain the wildcard `*` or echo the value\nof the `Origin` request header.\n\nIf the configuration contains the wildcard `*` in `allowOrigins` and\n`allowCredentials` is set to `true`, the gateway must not return `*`\nin the `Access-Control-Allow-Origin` response header. Instead, it must\nreturn a single origin matching the value of the `Origin` request header.\n\nSupport: Extended";
          type = (types.nullOr (types.listOf (types.withMaxLength 253 (types.withMinLength 1 types.str))));
        };
        "exposeHeaders" = mkOption {
          description = "ExposeHeaders indicates which HTTP response headers can be exposed\nto client-side scripts in response to a cross-origin request.\n\nA CORS-safelisted response header is an HTTP header in a CORS response\nthat it is considered safe to expose to the client scripts.\nThe CORS-safelisted response headers include the following headers:\n`Cache-Control`\n`Content-Language`\n`Content-Length`\n`Content-Type`\n`Expires`\n`Last-Modified`\n`Pragma`\n(See https://fetch.spec.whatwg.org/#cors-safelisted-response-header-name)\nThe CORS-safelisted response headers are exposed to client by default.\n\nWhen an HTTP header name is specified using the `exposeHeaders` field,\nthis additional header will be exposed as part of the response to the\nclient.\n\nHeader names are not case-sensitive.\n\nMultiple header names in the value of the `Access-Control-Expose-Headers`\nresponse header are separated by a comma (\",\").\n\nA wildcard indicates that the responses with all HTTP headers are exposed\nto clients.\n\nIf the configuration contains the wildcard `*` in `exposeHeaders` and\n`allowCredentials` is set to `false`, the `Access-Control-Expose-Headers`\nresponse header can contain the wildcard `*`.\n\nIf the configuration contains the wildcard `*` in `exposeHeaders` and\n`allowCredentials` is set to `true`, the gateway cannot use the `*`\nin the `Access-Control-Expose-Headers` response header.\n\nSupport: Extended";
          type = (types.nullOr (types.listOf (types.withMaxLength 256 (types.withMinLength 1 types.str))));
        };
        "maxAge" = mkOption {
          description = "MaxAge indicates the duration (in seconds) for the client to cache the\nresults of a \"preflight\" request.\n\nThe information provided by the `Access-Control-Allow-Methods` and\n`Access-Control-Allow-Headers` response headers can be cached by the\nclient until the time specified by `Access-Control-Max-Age` elapses.\n\nThe default value of `Access-Control-Max-Age` response header is 5\n(seconds).\n\nWhen the `MaxAge` field is unspecified, the gateway sets the response\nheader \"Access-Control-Max-Age: 5\" by default.";
          type = (types.nullOr (types.withMinimum 1 types.int));
        };
      };

      config = {
        "allowCredentials" = mkOverride 1002 null;
        "allowHeaders" = mkOverride 1002 null;
        "allowMethods" = mkOverride 1002 null;
        "allowOrigins" = mkOverride 1002 null;
        "exposeHeaders" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExtensionRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = (types.withMaxLength 253 types.str);
        };
        "kind" = mkOption {
          description = "Kind is kind of the referent. For example \"HTTPRoute\" or \"Service\".";
          type = (types.withMaxLength 63 (types.withMinLength 1 types.str));
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExternalAuth" = {

      options = {
        "backendRef" = mkOption {
          description = "BackendRef is a reference to a backend to send authorization\nrequests to.\n\nThe backend must speak the selected protocol (GRPC or HTTP) on the\nreferenced port.\n\nIf the backend service requires TLS, use BackendTLSPolicy to tell the\nimplementation to supply the TLS details to be used to connect to that\nbackend.";
          type = (
            submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExternalAuthBackendRef"
          );
        };
        "forwardBody" = mkOption {
          description = "ForwardBody controls if requests to the authorization server should include\nthe body of the client request; and if so, how big that body is allowed\nto be.\n\nIt is expected that implementations will buffer the request body up to\n`forwardBody.maxSize` bytes. Bodies over that size must be rejected with a\n4xx series error (413 or 403 are common examples), and fail processing\nof the filter.\n\nIf unset, or `forwardBody.maxSize` is set to `0`, then the body will not\nbe forwarded.\n\nFeature Name: HTTPRouteExternalAuthForwardBody";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExternalAuthForwardBody"
            )
          );
        };
        "grpc" = mkOption {
          description = "GRPCAuthConfig contains configuration for communication with ext_authz\nprotocol-speaking backends.\n\nIf unset, implementations must assume the default behavior for each\nincluded field is intended.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExternalAuthGrpc"
            )
          );
        };
        "http" = mkOption {
          description = "HTTPAuthConfig contains configuration for communication with HTTP-speaking\nbackends.\n\nIf unset, implementations must assume the default behavior for each\nincluded field is intended.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExternalAuthHttp"
            )
          );
        };
        "protocol" = mkOption {
          description = "ExternalAuthProtocol describes which protocol to use when communicating with an\next_authz authorization server.\n\nWhen this is set to GRPC, each backend must use the Envoy ext_authz protocol\non the port specified in `backendRefs`. Requests and responses are defined\nin the protobufs explained at:\nhttps://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto\n\nWhen this is set to HTTP, each backend must respond with a `200` status\ncode in on a successful authorization. Any other code is considered\nan authorization failure.\n\nFeature Names:\nGRPC Support - HTTPRouteExternalAuthGRPC\nHTTP Support - HTTPRouteExternalAuthHTTP";
          type = (
            types.enum [
              "HTTP"
              "GRPC"
            ]
          );
        };
      };

      config = {
        "forwardBody" = mkOverride 1002 null;
        "grpc" = mkOverride 1002 null;
        "http" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExternalAuthBackendRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = (types.nullOr (types.withMaxLength 253 types.str));
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 1 types.int)));
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExternalAuthForwardBody" = {

      options = {
        "maxSize" = mkOption {
          description = "MaxSize specifies how large in bytes the largest body that will be buffered\nand sent to the authorization server. If the body size is larger than\n`maxSize`, then the body sent to the authorization server must be\ntruncated to `maxSize` bytes.\n\nExperimental note: This behavior needs to be checked against\nvarious dataplanes; it may need to be changed.\nSee https://github.com/kubernetes-sigs/gateway-api/pull/4001#discussion_r2291405746\nfor more.\n\nIf 0, the body will not be sent to the authorization server.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "maxSize" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExternalAuthGrpc" = {

      options = {
        "allowedHeaders" = mkOption {
          description = "AllowedRequestHeaders specifies what headers from the client request\nwill be sent to the authorization server.\n\nIf this list is empty, then all headers must be sent.\n\nIf the list has entries, only those entries must be sent.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "allowedHeaders" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersExternalAuthHttp" = {

      options = {
        "allowedHeaders" = mkOption {
          description = "AllowedRequestHeaders specifies what additional headers from the client request\nwill be sent to the authorization server.\n\nThe following headers must always be sent to the authorization server,\nregardless of this setting:\n\n* `Host`\n* `Method`\n* `Path`\n* `Content-Length`\n* `Authorization`\n\nIf this list is empty, then only those headers must be sent.\n\nNote that `Content-Length` has a special behavior, in that the length\nsent must be correct for the actual request to the external authorization\nserver - that is, it must reflect the actual number of bytes sent in the\nbody of the request to the authorization server.\n\nSo if the `forwardBody` stanza is unset, or `forwardBody.maxSize` is set\nto `0`, then `Content-Length` must be `0`. If `forwardBody.maxSize` is set\nto anything other than `0`, then the `Content-Length` of the authorization\nrequest must be set to the actual number of bytes forwarded.";
          type = (types.nullOr (types.listOf types.str));
        };
        "allowedResponseHeaders" = mkOption {
          description = "AllowedResponseHeaders specifies what headers from the authorization response\nwill be copied into the request to the backend.\n\nIf this list is empty, then all headers from the authorization server\nexcept Authority or Host must be copied.";
          type = (types.nullOr (types.listOf types.str));
        };
        "path" = mkOption {
          description = "Path sets the prefix that paths from the client request will have added\nwhen forwarded to the authorization server.\n\nWhen empty or unspecified, no prefix is added.\n\nValid values are the same as the \"value\" regex for path values in the `match`\nstanza, and the validation regex will screen out invalid paths in the same way.\nEven with the validation, implementations MUST sanitize this input before using it\ndirectly.";
          type = (types.nullOr (types.withMaxLength 1024 types.str));
        };
      };

      config = {
        "allowedHeaders" = mkOverride 1002 null;
        "allowedResponseHeaders" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestHeaderModifierAdd"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = (types.nullOr (types.listOf types.str));
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestHeaderModifierSet"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = (types.withMaxLength 256 (types.withMinLength 1 types.str));
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.\n<gateway:experimental:description>\nMust consist of printable US-ASCII characters, optionally separated\nby single tabs or spaces. See: https://tools.ietf.org/html/rfc7230#section-3.2\n</gateway:experimental:description>\n\n<gateway:experimental:validation:Pattern=`^[!-~]+([\\t ]?[!-~]+)*$`>";
          type = (types.withMaxLength 4096 (types.withMinLength 1 types.str));
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = (types.withMaxLength 256 (types.withMinLength 1 types.str));
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.\n<gateway:experimental:description>\nMust consist of printable US-ASCII characters, optionally separated\nby single tabs or spaces. See: https://tools.ietf.org/html/rfc7230#section-3.2\n</gateway:experimental:description>\n\n<gateway:experimental:validation:Pattern=`^[!-~]+([\\t ]?[!-~]+)*$`>";
          type = (types.withMaxLength 4096 (types.withMinLength 1 types.str));
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestMirror" = {

      options = {
        "backendRef" = mkOption {
          description = "BackendRef references a resource where mirrored requests are sent.\n\nMirrored requests must be sent only to a single destination endpoint\nwithin this BackendRef, irrespective of how many endpoints are present\nwithin this BackendRef.\n\nIf the referent cannot be found, this BackendRef is invalid and must be\ndropped from the Gateway. The controller must ensure the \"ResolvedRefs\"\ncondition on the Route status is set to `status: False` and not configure\nthis backend in the underlying implementation.\n\nIf there is a cross-namespace reference to an *existing* object\nthat is not allowed by a ReferenceGrant, the controller must ensure the\n\"ResolvedRefs\"  condition on the Route is set to `status: False`,\nwith the \"RefNotPermitted\" reason and not configure this backend in the\nunderlying implementation.\n\nIn either error case, the Message of the `ResolvedRefs` Condition\nshould be used to provide more detail about the problem.\n\nSupport: Extended for Kubernetes Service\n\nSupport: Implementation-specific for any other resource\n\nIf the backend service requires TLS, use BackendTLSPolicy to tell the\nimplementation to supply the TLS details to be used to connect to that\nbackend.";
          type = (
            submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestMirrorBackendRef"
          );
        };
        "fraction" = mkOption {
          description = "Fraction represents the fraction of requests that should be\nmirrored to BackendRef.\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestMirrorFraction"
            )
          );
        };
        "percent" = mkOption {
          description = "Percent represents the percentage of requests that should be\nmirrored to BackendRef. Its minimum value is 0 (indicating 0% of\nrequests) and its maximum value is 100 (indicating 100% of requests).\n\nOnly one of Fraction or Percent may be specified. If neither field\nis specified, 100% of requests will be mirrored.";
          type = (types.nullOr (types.withMaximum 100 (types.withMinimum 0 types.int)));
        };
      };

      config = {
        "fraction" = mkOverride 1002 null;
        "percent" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestMirrorBackendRef" = {

      options = {
        "group" = mkOption {
          description = "Group is the group of the referent. For example, \"gateway.networking.k8s.io\".\nWhen unspecified or empty string, core API group is inferred.";
          type = (types.nullOr (types.withMaxLength 253 types.str));
        };
        "kind" = mkOption {
          description = "Kind is the Kubernetes resource kind of the referent. For example\n\"Service\".\n\nDefaults to \"Service\" when not specified.\n\nExternalName services can refer to CNAME DNS records that may live\noutside of the cluster and as such are difficult to reason about in\nterms of conformance. They also may not be safe to forward to (see\nCVE-2021-25740 for more information). Implementations SHOULD NOT\nsupport ExternalName Services.\n\nSupport: Core (Services with a type other than ExternalName)\n\nSupport: Implementation-specific (Services with type ExternalName)";
          type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
        };
        "name" = mkOption {
          description = "Name is the name of the referent.";
          type = (types.withMaxLength 253 (types.withMinLength 1 types.str));
        };
        "namespace" = mkOption {
          description = "Namespace is the namespace of the backend. When unspecified, the local\nnamespace is inferred.\n\nNote that when a namespace different than the local namespace is specified,\na ReferenceGrant object is required in the referent namespace to allow that\nnamespace's owner to accept the reference. See the ReferenceGrant\ndocumentation for details.\n\nSupport: Core";
          type = (types.nullOr (types.withMaxLength 63 (types.withMinLength 1 types.str)));
        };
        "port" = mkOption {
          description = "Port specifies the destination port number to use for this resource.\nPort is required when the referent is a Kubernetes Service. In this\ncase, the port number is the service port number, not the target port.\nFor other resources, destination port might be derived from the referent\nresource or this field.";
          type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 1 types.int)));
        };
      };

      config = {
        "group" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestMirrorFraction" = {

      options = {
        "denominator" = mkOption {
          description = "";
          type = (types.nullOr (types.withMinimum 1 types.int));
        };
        "numerator" = mkOption {
          description = "";
          type = (types.withMinimum 0 types.int);
        };
      };

      config = {
        "denominator" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestRedirect" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the hostname to be used in the value of the `Location`\nheader in the response.\nWhen empty, the hostname in the `Host` header of the request is used.\n\nSupport: Core";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
        "path" = mkOption {
          description = "Path defines parameters used to modify the path of the incoming request.\nThe modified path is then used to construct the `Location` header. When\nempty, the request path is used as-is.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestRedirectPath"
            )
          );
        };
        "port" = mkOption {
          description = "Port is the port to be used in the value of the `Location`\nheader in the response.\n\nIf no port is specified, the redirect port MUST be derived using the\nfollowing rules:\n\n* If redirect scheme is not-empty, the redirect port MUST be the well-known\n  port associated with the redirect scheme. Specifically \"http\" to port 80\n  and \"https\" to port 443. If the redirect scheme does not have a\n  well-known port, the listener port of the Gateway SHOULD be used.\n* If redirect scheme is empty, the redirect port MUST be the Gateway\n  Listener port.\n\nImplementations SHOULD NOT add the port number in the 'Location'\nheader in the following cases:\n\n* A Location header that will use HTTP (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 80.\n* A Location header that will use HTTPS (whether that is determined via\n  the Listener protocol or the Scheme field) _and_ use port 443.\n\nSupport: Extended";
          type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 1 types.int)));
        };
        "scheme" = mkOption {
          description = "Scheme is the scheme to be used in the value of the `Location` header in\nthe response. When empty, the scheme of the request is used.\n\nScheme redirects can affect the port of the redirect, for more information,\nrefer to the documentation for the port field of this filter.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Extended";
          type = (
            types.nullOr (
              types.enum [
                "http"
                "https"
              ]
            )
          );
        };
        "statusCode" = mkOption {
          description = "StatusCode is the HTTP status code to be used in response.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.\n\nSupport: Core";
          type = (
            types.nullOr (
              types.enum [
                301
                302
                303
                307
                308
              ]
            )
          );
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "scheme" = mkOverride 1002 null;
        "statusCode" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersRequestRedirectPath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = (types.nullOr (types.withMaxLength 1024 types.str));
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = (types.nullOr (types.withMaxLength 1024 types.str));
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = (
            types.enum [
              "ReplaceFullPath"
              "ReplacePrefixMatch"
            ]
          );
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersResponseHeaderModifier" = {

      options = {
        "add" = mkOption {
          description = "Add adds the given header(s) (name, value) to the request\nbefore the action. It appends to any existing values associated\nwith the header name.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  add:\n  - name: \"my-header\"\n    value: \"bar,baz\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: foo,bar,baz";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersResponseHeaderModifierAdd"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "remove" = mkOption {
          description = "Remove the given header(s) from the HTTP request before the action. The\nvalue of Remove is a list of HTTP header names. Note that the header\nnames are case-insensitive (see\nhttps://datatracker.ietf.org/doc/html/rfc2616#section-4.2).\n\nInput:\n  GET /foo HTTP/1.1\n  my-header1: foo\n  my-header2: bar\n  my-header3: baz\n\nConfig:\n  remove: [\"my-header1\", \"my-header3\"]\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header2: bar";
          type = (types.nullOr (types.listOf types.str));
        };
        "set" = mkOption {
          description = "Set overwrites the request with the given header (name, value)\nbefore the action.\n\nInput:\n  GET /foo HTTP/1.1\n  my-header: foo\n\nConfig:\n  set:\n  - name: \"my-header\"\n    value: \"bar\"\n\nOutput:\n  GET /foo HTTP/1.1\n  my-header: bar";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersResponseHeaderModifierSet"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "add" = mkOverride 1002 null;
        "remove" = mkOverride 1002 null;
        "set" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersResponseHeaderModifierAdd" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = (types.withMaxLength 256 (types.withMinLength 1 types.str));
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.\n<gateway:experimental:description>\nMust consist of printable US-ASCII characters, optionally separated\nby single tabs or spaces. See: https://tools.ietf.org/html/rfc7230#section-3.2\n</gateway:experimental:description>\n\n<gateway:experimental:validation:Pattern=`^[!-~]+([\\t ]?[!-~]+)*$`>";
          type = (types.withMaxLength 4096 (types.withMinLength 1 types.str));
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersResponseHeaderModifierSet" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, the first entry with\nan equivalent name MUST be considered for a match. Subsequent entries\nwith an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.";
          type = (types.withMaxLength 256 (types.withMinLength 1 types.str));
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.\n<gateway:experimental:description>\nMust consist of printable US-ASCII characters, optionally separated\nby single tabs or spaces. See: https://tools.ietf.org/html/rfc7230#section-3.2\n</gateway:experimental:description>\n\n<gateway:experimental:validation:Pattern=`^[!-~]+([\\t ]?[!-~]+)*$`>";
          type = (types.withMaxLength 4096 (types.withMinLength 1 types.str));
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersUrlRewrite" = {

      options = {
        "hostname" = mkOption {
          description = "Hostname is the value to be used to replace the Host header value during\nforwarding.\n\nSupport: Extended";
          type = (types.nullOr (types.withMaxLength 253 (types.withMinLength 1 types.str)));
        };
        "path" = mkOption {
          description = "Path defines a path rewrite.\n\nSupport: Extended";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersUrlRewritePath"
            )
          );
        };
      };

      config = {
        "hostname" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesFiltersUrlRewritePath" = {

      options = {
        "replaceFullPath" = mkOption {
          description = "ReplaceFullPath specifies the value with which to replace the full path\nof a request during a rewrite or redirect.";
          type = (types.nullOr (types.withMaxLength 1024 types.str));
        };
        "replacePrefixMatch" = mkOption {
          description = "ReplacePrefixMatch specifies the value with which to replace the prefix\nmatch of a request during a rewrite or redirect. For example, a request\nto \"/foo/bar\" with a prefix match of \"/foo\" and a ReplacePrefixMatch\nof \"/xyz\" would be modified to \"/xyz/bar\".\n\nNote that this matches the behavior of the PathPrefix match type. This\nmatches full path elements. A path element refers to the list of labels\nin the path split by the `/` separator. When specified, a trailing `/` is\nignored. For example, the paths `/abc`, `/abc/`, and `/abc/def` would all\nmatch the prefix `/abc`, but the path `/abcd` would not.\n\nReplacePrefixMatch is only compatible with a `PathPrefix` HTTPRouteMatch.\nUsing any other HTTPRouteMatch type on the same HTTPRouteRule will result in\nthe implementation setting the Accepted Condition for the Route to `status: False`.\n\nRequest Path | Prefix Match | Replace Prefix | Modified Path";
          type = (types.nullOr (types.withMaxLength 1024 types.str));
        };
        "type" = mkOption {
          description = "Type defines the type of path modifier. Additional types may be\nadded in a future release of the API.\n\nNote that values may be added to this enum, implementations\nmust ensure that unknown values will not cause a crash.\n\nUnknown values here must result in the implementation setting the\nAccepted Condition for the Route to `status: False`, with a\nReason of `UnsupportedValue`.";
          type = (
            types.enum [
              "ReplaceFullPath"
              "ReplacePrefixMatch"
            ]
          );
        };
      };

      config = {
        "replaceFullPath" = mkOverride 1002 null;
        "replacePrefixMatch" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesMatches" = {

      options = {
        "headers" = mkOption {
          description = "Headers specifies HTTP request header matchers. Multiple match values are\nANDed together, meaning, a request must match all the specified headers\nto select the route.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesMatchesHeaders"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "method" = mkOption {
          description = "Method specifies HTTP method matcher.\nWhen specified, this route will be matched only if the request has the\nspecified method.\n\nSupport: Extended";
          type = (
            types.nullOr (
              types.enum [
                "GET"
                "HEAD"
                "POST"
                "PUT"
                "DELETE"
                "CONNECT"
                "OPTIONS"
                "TRACE"
                "PATCH"
              ]
            )
          );
        };
        "path" = mkOption {
          description = "Path specifies a HTTP request path matcher. If this field is not\nspecified, a default prefix match on the \"/\" path is provided.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesMatchesPath"
            )
          );
        };
        "queryParams" = mkOption {
          description = "QueryParams specifies HTTP query parameter matchers. Multiple match\nvalues are ANDed together, meaning, a request must match all the\nspecified query parameters to select the route.\n\nSupport: Extended";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesMatchesQueryParams"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "headers" = mkOverride 1002 null;
        "method" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "queryParams" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesMatchesHeaders" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP Header to be matched. Name matching MUST be\ncase-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).\n\nIf multiple entries specify equivalent header names, only the first\nentry with an equivalent name MUST be considered for a match. Subsequent\nentries with an equivalent header name MUST be ignored. Due to the\ncase-insensitivity of header names, \"foo\" and \"Foo\" are considered\nequivalent.\n\nWhen a header is repeated in an HTTP request, it is\nimplementation-specific behavior as to how this is represented.\nGenerally, proxies should follow the guidance from the RFC:\nhttps://www.rfc-editor.org/rfc/rfc7230.html#section-3.2.2 regarding\nprocessing a repeated header, with special handling for \"Set-Cookie\".";
          type = (types.withMaxLength 256 (types.withMinLength 1 types.str));
        };
        "type" = mkOption {
          description = "Type specifies how to match against the value of the header.\n\nSupport: Core (Exact)\n\nSupport: Implementation-specific (RegularExpression)\n\nSince RegularExpression HeaderMatchType has implementation-specific\nconformance, implementations can support POSIX, PCRE or any other dialects\nof regular expressions. Please read the implementation's documentation to\ndetermine the supported dialect.";
          type = (
            types.nullOr (
              types.enum [
                "Exact"
                "RegularExpression"
              ]
            )
          );
        };
        "value" = mkOption {
          description = "Value is the value of HTTP Header to be matched.\n<gateway:experimental:description>\nMust consist of printable US-ASCII characters, optionally separated\nby single tabs or spaces. See: https://tools.ietf.org/html/rfc7230#section-3.2\n</gateway:experimental:description>\n\n<gateway:experimental:validation:Pattern=`^[!-~]+([\\t ]?[!-~]+)*$`>";
          type = (types.withMaxLength 4096 (types.withMinLength 1 types.str));
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesMatchesPath" = {

      options = {
        "type" = mkOption {
          description = "Type specifies how to match against the path Value.\n\nSupport: Core (Exact, PathPrefix)\n\nSupport: Implementation-specific (RegularExpression)";
          type = (
            types.nullOr (
              types.enum [
                "Exact"
                "PathPrefix"
                "RegularExpression"
              ]
            )
          );
        };
        "value" = mkOption {
          description = "Value of the HTTP path to match against.";
          type = (types.nullOr (types.withMaxLength 1024 types.str));
        };
      };

      config = {
        "type" = mkOverride 1002 null;
        "value" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesMatchesQueryParams" = {

      options = {
        "name" = mkOption {
          description = "Name is the name of the HTTP query param to be matched. This must be an\nexact string match. (See\nhttps://tools.ietf.org/html/rfc7230#section-2.7.3).\n\nIf multiple entries specify equivalent query param names, only the first\nentry with an equivalent name MUST be considered for a match. Subsequent\nentries with an equivalent query param name MUST be ignored.\n\nIf a query param is repeated in an HTTP request, the behavior is\npurposely left undefined, since different data planes have different\ncapabilities. However, it is *recommended* that implementations should\nmatch against the first value of the param if the data plane supports it,\nas this behavior is expected in other load balancing contexts outside of\nthe Gateway API.\n\nUsers SHOULD NOT route traffic based on repeated query params to guard\nthemselves against potential differences in the implementations.";
          type = (types.withMaxLength 256 (types.withMinLength 1 types.str));
        };
        "type" = mkOption {
          description = "Type specifies how to match against the value of the query parameter.\n\nSupport: Extended (Exact)\n\nSupport: Implementation-specific (RegularExpression)\n\nSince RegularExpression QueryParamMatchType has Implementation-specific\nconformance, implementations can support POSIX, PCRE or any other\ndialects of regular expressions. Please read the implementation's\ndocumentation to determine the supported dialect.";
          type = (
            types.nullOr (
              types.enum [
                "Exact"
                "RegularExpression"
              ]
            )
          );
        };
        "value" = mkOption {
          description = "Value is the value of HTTP query param to be matched.";
          type = (types.withMaxLength 1024 (types.withMinLength 1 types.str));
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesRetry" = {

      options = {
        "attempts" = mkOption {
          description = "Attempts specifies the maximum number of times an individual request\nfrom the gateway to a backend should be retried.\n\nIf the maximum number of retries has been attempted without a successful\nresponse from the backend, the Gateway MUST return an error.\n\nWhen this field is unspecified, the number of times to attempt to retry\na backend request is implementation-specific.\n\nSupport: Extended";
          type = (types.nullOr (types.withMinimum 1 types.int));
        };
        "backoff" = mkOption {
          description = "Backoff specifies the minimum duration a Gateway should wait between\nretry attempts and is represented in Gateway API Duration formatting.\n\nFor example, setting the `rules[].retry.backoff` field to the value\n`100ms` will cause a backend request to first be retried approximately\n100 milliseconds after timing out or receiving a response code configured\nto be retriable.\n\nAn implementation MAY use an exponential or alternative backoff strategy\nfor subsequent retry attempts, MAY cap the maximum backoff duration to\nsome amount greater than the specified minimum, and MAY add arbitrary\njitter to stagger requests, as long as unsuccessful backend requests are\nnot retried before the configured minimum duration.\n\nIf a Request timeout (`rules[].timeouts.request`) is configured on the\nroute, the entire duration of the initial request and any retry attempts\nMUST not exceed the Request timeout duration. If any retry attempts are\nstill in progress when the Request timeout duration has been reached,\nthese SHOULD be canceled if possible and the Gateway MUST immediately\nreturn a timeout error.\n\nIf a BackendRequest timeout (`rules[].timeouts.backendRequest`) is\nconfigured on the route, any retry attempts which reach the configured\nBackendRequest timeout duration without a response SHOULD be canceled if\npossible and the Gateway should wait for at least the specified backoff\nduration before attempting to retry the backend request again.\n\nIf a BackendRequest timeout is _not_ configured on the route, retry\nattempts MAY time out after an implementation default duration, or MAY\nremain pending until a configured Request timeout or implementation\ndefault duration for total request time is reached.\n\nWhen this field is unspecified, the time to wait between retry attempts\nis implementation-specific.\n\nSupport: Extended";
          type = (types.nullOr types.str);
        };
        "codes" = mkOption {
          description = "Codes defines the HTTP response status codes for which a backend request\nshould be retried.\n\nSupport: Extended";
          type = (types.nullOr (types.listOf (types.withMaximum 599 (types.withMinimum 400 types.int))));
        };
      };

      config = {
        "attempts" = mkOverride 1002 null;
        "backoff" = mkOverride 1002 null;
        "codes" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesSessionPersistence" = {

      options = {
        "absoluteTimeout" = mkOption {
          description = "AbsoluteTimeout defines the absolute timeout of the persistent\nsession. Once the AbsoluteTimeout duration has elapsed, the\nsession becomes invalid.\n\nSupport: Extended";
          type = (types.nullOr types.str);
        };
        "cookieConfig" = mkOption {
          description = "CookieConfig provides configuration settings that are specific\nto cookie-based session persistence.\n\nSupport: Core";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesSessionPersistenceCookieConfig"
            )
          );
        };
        "sessionName" = mkOption {
          description = "SessionName defines the name of the persistent session token\nwhich may be reflected in the cookie or the header. Users\nshould avoid reusing session names to prevent unintended\nconsequences, such as rejection or unpredictable behavior.\n\nSupport: Implementation-specific";
          type = (types.nullOr (types.withMaxLength 128 types.str));
        };
        "type" = mkOption {
          description = "Type defines the type of session persistence such as through\nthe use of a header or cookie. Defaults to cookie based session\npersistence.\n\nSupport: Core for \"Cookie\" type\n\nSupport: Extended for \"Header\" type";
          type = (
            types.nullOr (
              types.enum [
                "Cookie"
                "Header"
              ]
            )
          );
        };
      };

      config = {
        "absoluteTimeout" = mkOverride 1002 null;
        "cookieConfig" = mkOverride 1002 null;
        "sessionName" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesSessionPersistenceCookieConfig" = {

      options = {
        "lifetimeType" = mkOption {
          description = "LifetimeType specifies whether the cookie has a permanent or\nsession-based lifetime. A permanent cookie persists until its\nspecified expiry time, defined by the Expires or Max-Age cookie\nattributes, while a session cookie is deleted when the current\nsession ends.\n\nWhen set to \"Permanent\", AbsoluteTimeout indicates the\ncookie's lifetime via the Expires or Max-Age cookie attributes\nand is required.\n\nWhen set to \"Session\", AbsoluteTimeout indicates the\nabsolute lifetime of the cookie tracked by the gateway and\nis optional.\n\nDefaults to \"Session\".\n\nSupport: Core for \"Session\" type\n\nSupport: Extended for \"Permanent\" type";
          type = (
            types.nullOr (
              types.enum [
                "Permanent"
                "Session"
              ]
            )
          );
        };
      };

      config = {
        "lifetimeType" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecHttpRouteSpecRulesTimeouts" = {

      options = {
        "backendRequest" = mkOption {
          description = "BackendRequest specifies a timeout for an individual request from the gateway\nto a backend. This covers the time from when the request first starts being\nsent from the gateway to when the full response has been received from the backend.\n\nSetting a timeout to the zero duration (e.g. \"0s\") SHOULD disable the timeout\ncompletely. Implementations that cannot completely disable the timeout MUST\ninstead interpret the zero duration as the longest possible value to which\nthe timeout can be set.\n\nAn entire client HTTP transaction with a gateway, covered by the Request timeout,\nmay result in more than one call from the gateway to the destination backend,\nfor example, if automatic retries are supported.\n\nThe value of BackendRequest must be a Gateway API Duration string as defined by\nGEP-2257.  When this field is unspecified, its behavior is implementation-specific;\nwhen specified, the value of BackendRequest must be no more than the value of the\nRequest timeout (since the Request timeout encompasses the BackendRequest timeout).\n\nSupport: Extended";
          type = (types.nullOr types.str);
        };
        "request" = mkOption {
          description = "Request specifies the maximum duration for a gateway to respond to an HTTP request.\nIf the gateway has not been able to respond before this deadline is met, the gateway\nMUST return a timeout error.\n\nFor example, setting the `rules.timeouts.request` field to the value `10s` in an\n`HTTPRoute` will cause a timeout if a client request is taking longer than 10 seconds\nto complete.\n\nSetting a timeout to the zero duration (e.g. \"0s\") SHOULD disable the timeout\ncompletely. Implementations that cannot completely disable the timeout MUST\ninstead interpret the zero duration as the longest possible value to which\nthe timeout can be set.\n\nThis timeout is intended to cover as close to the whole request-response transaction\nas possible although an implementation MAY choose to start the timeout after the entire\nrequest stream has been received instead of immediately after the transaction is\ninitiated by the client.\n\nThe value of Request is a Gateway API Duration string as defined by GEP-2257. When this\nfield is unspecified, request timeout behavior is implementation-specific.\n\nSupport: Extended";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "backendRequest" = mkOverride 1002 null;
        "request" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngress" = {

      options = {
        "metadata" = mkOption {
          description = "ObjectMeta contains only a [subset of the fields included in k8s.io/apimachinery/pkg/apis/meta/v1.ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#objectmeta-v1-meta).";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressMetadata"));
        };
        "spec" = mkOption {
          description = "IngressSpec describes the Ingress the user wishes to exist.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpec"));
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpec" = {

      options = {
        "defaultBackend" = mkOption {
          description = "defaultBackend is the backend that should handle requests that don't\nmatch any rule. If Rules are not specified, DefaultBackend must be specified.\nIf DefaultBackend is not set, the handling of requests that do not match any\nof the rules will be up to the Ingress controller.";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecDefaultBackend")
          );
        };
        "ingressClassName" = mkOption {
          description = "ingressClassName is the name of an IngressClass cluster resource. Ingress\ncontroller implementations use this field to know whether they should be\nserving this Ingress resource, by a transitive connection\n(controller -> IngressClass -> Ingress resource). Although the\n`kubernetes.io/ingress.class` annotation (simple constant name) was never\nformally defined, it was widely supported by Ingress controllers to create\na direct binding between Ingress controller and Ingress resources. Newly\ncreated Ingress resources should prefer using the field. However, even\nthough the annotation is officially deprecated, for backwards compatibility\nreasons, ingress controllers should still honor that annotation if present.";
          type = (types.nullOr types.str);
        };
        "rules" = mkOption {
          description = "rules is a list of host rules used to configure the Ingress. If unspecified,\nor no rule matches, all traffic is sent to the default backend.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRules")
            )
          );
        };
        "tls" = mkOption {
          description = "tls represents the TLS configuration. Currently the Ingress only supports a\nsingle TLS port, 443. If multiple members of this list specify different hosts,\nthey will be multiplexed on the same port according to the hostname specified\nthrough the SNI TLS extension, if the ingress controller fulfilling the\ningress supports SNI.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecTls")
            )
          );
        };
      };

      config = {
        "defaultBackend" = mkOverride 1002 null;
        "ingressClassName" = mkOverride 1002 null;
        "rules" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecDefaultBackend" = {

      options = {
        "resource" = mkOption {
          description = "resource is an ObjectRef to another Kubernetes resource in the namespace\nof the Ingress object. If resource is specified, a service.Name and\nservice.Port must not be specified.\nThis is a mutually exclusive setting with \"Service\".";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecDefaultBackendResource"
            )
          );
        };
        "service" = mkOption {
          description = "service references a service as a backend.\nThis is a mutually exclusive setting with \"Resource\".";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecDefaultBackendService"
            )
          );
        };
      };

      config = {
        "resource" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecDefaultBackendResource" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced.\nIf APIGroup is not specified, the specified Kind must be in the core API group.\nFor any other third-party types, APIGroup is required.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced";
          type = types.str;
        };
      };

      config = {
        "apiGroup" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecDefaultBackendService" = {

      options = {
        "name" = mkOption {
          description = "name is the referenced service. The service must exist in\nthe same namespace as the Ingress object.";
          type = types.str;
        };
        "port" = mkOption {
          description = "port of the referenced service. A port name or port number\nis required for a IngressServiceBackend.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecDefaultBackendServicePort"
            )
          );
        };
      };

      config = {
        "port" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecDefaultBackendServicePort" = {

      options = {
        "name" = mkOption {
          description = "name is the name of the port on the Service.\nThis is a mutually exclusive setting with \"Number\".";
          type = (types.nullOr types.str);
        };
        "number" = mkOption {
          description = "number is the numerical port number (e.g. 80) on the Service.\nThis is a mutually exclusive setting with \"Name\".";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "number" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRules" = {

      options = {
        "host" = mkOption {
          description = "host is the fully qualified domain name of a network host, as defined by RFC 3986.\nNote the following deviations from the \"host\" part of the\nURI as defined in RFC 3986:\n1. IPs are not allowed. Currently an IngressRuleValue can only apply to\n   the IP in the Spec of the parent Ingress.\n2. The `:` delimiter is not respected because ports are not allowed.\n\t  Currently the port of an Ingress is implicitly :80 for http and\n\t  :443 for https.\nBoth these may change in the future.\nIncoming requests are matched against the host before the\nIngressRuleValue. If the host is unspecified, the Ingress routes all\ntraffic based on the specified IngressRuleValue.\n\nhost can be \"precise\" which is a domain name without the terminating dot of\na network host (e.g. \"foo.bar.com\") or \"wildcard\", which is a domain name\nprefixed with a single wildcard label (e.g. \"*.foo.com\").\nThe wildcard character '*' must appear by itself as the first DNS label and\nmatches only a single label. You cannot have a wildcard label by itself (e.g. Host == \"*\").\nRequests will be matched against the Host field in the following way:\n1. If host is precise, the request matches this rule if the http host header is equal to Host.\n2. If host is a wildcard, then the request matches this rule if the http host header\nis to equal to the suffix (removing the first label) of the wildcard rule.";
          type = (types.nullOr types.str);
        };
        "http" = mkOption {
          description = "HTTPIngressRuleValue is a list of http selectors pointing to backends.\nIn the example: http://<host>/<path>?<searchpart> -> backend where\nwhere parts of the url correspond to RFC 3986, this resource will be used\nto match against everything after the last '/' and before the first '?'\nor '#'.";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttp")
          );
        };
      };

      config = {
        "host" = mkOverride 1002 null;
        "http" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttp" = {

      options = {
        "paths" = mkOption {
          description = "paths is a collection of paths that map requests to backends.";
          type = (
            types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttpPaths")
          );
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttpPaths" = {

      options = {
        "backend" = mkOption {
          description = "backend defines the referenced service endpoint to which the traffic\nwill be forwarded to.";
          type = (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttpPathsBackend");
        };
        "path" = mkOption {
          description = "path is matched against the path of an incoming request. Currently it can\ncontain characters disallowed from the conventional \"path\" part of a URL\nas defined by RFC 3986. Paths must begin with a '/' and must be present\nwhen using PathType with value \"Exact\" or \"Prefix\".";
          type = (types.nullOr types.str);
        };
        "pathType" = mkOption {
          description = "pathType determines the interpretation of the path matching. PathType can\nbe one of the following values:\n* Exact: Matches the URL path exactly.\n* Prefix: Matches based on a URL path prefix split by '/'. Matching is\n  done on a path element by element basis. A path element refers is the\n  list of labels in the path split by the '/' separator. A request is a\n  match for path p if every p is an element-wise prefix of p of the\n  request path. Note that if the last element of the path is a substring\n  of the last element in request path, it is not a match (e.g. /foo/bar\n  matches /foo/bar/baz, but does not match /foo/barbaz).\n* ImplementationSpecific: Interpretation of the Path matching is up to\n  the IngressClass. Implementations can treat this as a separate PathType\n  or treat it identically to Prefix or Exact path types.\nImplementations are required to support all path types.";
          type = types.str;
        };
      };

      config = {
        "path" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttpPathsBackend" = {

      options = {
        "resource" = mkOption {
          description = "resource is an ObjectRef to another Kubernetes resource in the namespace\nof the Ingress object. If resource is specified, a service.Name and\nservice.Port must not be specified.\nThis is a mutually exclusive setting with \"Service\".";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttpPathsBackendResource"
            )
          );
        };
        "service" = mkOption {
          description = "service references a service as a backend.\nThis is a mutually exclusive setting with \"Resource\".";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttpPathsBackendService"
            )
          );
        };
      };

      config = {
        "resource" = mkOverride 1002 null;
        "service" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttpPathsBackendResource" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced.\nIf APIGroup is not specified, the specified Kind must be in the core API group.\nFor any other third-party types, APIGroup is required.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced";
          type = types.str;
        };
      };

      config = {
        "apiGroup" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttpPathsBackendService" = {

      options = {
        "name" = mkOption {
          description = "name is the referenced service. The service must exist in\nthe same namespace as the Ingress object.";
          type = types.str;
        };
        "port" = mkOption {
          description = "port of the referenced service. A port name or port number\nis required for a IngressServiceBackend.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttpPathsBackendServicePort"
            )
          );
        };
      };

      config = {
        "port" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecRulesHttpPathsBackendServicePort" = {

      options = {
        "name" = mkOption {
          description = "name is the name of the port on the Service.\nThis is a mutually exclusive setting with \"Number\".";
          type = (types.nullOr types.str);
        };
        "number" = mkOption {
          description = "number is the numerical port number (e.g. 80) on the Service.\nThis is a mutually exclusive setting with \"Name\".";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "number" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecIngressSpecTls" = {

      options = {
        "hosts" = mkOption {
          description = "hosts is a list of hosts included in the TLS certificate. The values in\nthis list must match the name/s used in the tlsSecret. Defaults to the\nwildcard host setting for the loadbalancer controller fulfilling this\nIngress, if left unspecified.";
          type = (types.nullOr (types.listOf types.str));
        };
        "secretName" = mkOption {
          description = "secretName is the name of the secret used to terminate TLS traffic on\nport 443. Field is left optional to allow TLS routing based on SNI\nhostname alone. If the SNI host in a listener conflicts with the \"Host\"\nheader field used by an IngressRule, the SNI host is used for termination\nand value of the \"Host\" header is used for routing.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "hosts" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecJsonnet" = {

      options = {
        "libraryLabelSelector" = mkOption {
          description = "A label selector is a label query over a set of resources. The result of matchLabels and\nmatchExpressions are ANDed. An empty label selector matches all objects. A null\nlabel selector matches no objects.";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecJsonnetLibraryLabelSelector")
          );
        };
      };

      config = {
        "libraryLabelSelector" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecJsonnetLibraryLabelSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecJsonnetLibraryLabelSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaSpecJsonnetLibraryLabelSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaim" = {

      options = {
        "metadata" = mkOption {
          description = "ObjectMeta contains only a [subset of the fields included in k8s.io/apimachinery/pkg/apis/meta/v1.ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#objectmeta-v1-meta).";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimMetadata"
            )
          );
        };
        "spec" = mkOption {
          description = "";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpec")
          );
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpec" = {

      options = {
        "accessModes" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "dataSource" = mkOption {
          description = "TypedLocalObjectReference contains enough information to let you locate the\ntyped referenced object inside the same namespace.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecDataSource"
            )
          );
        };
        "dataSourceRef" = mkOption {
          description = "TypedLocalObjectReference contains enough information to let you locate the\ntyped referenced object inside the same namespace.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecDataSourceRef"
            )
          );
        };
        "resources" = mkOption {
          description = "ResourceRequirements describes the compute resource requirements.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecResources"
            )
          );
        };
        "selector" = mkOption {
          description = "A label selector is a label query over a set of resources. The result of matchLabels and\nmatchExpressions are ANDed. An empty label selector matches all objects. A null\nlabel selector matches no objects.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecSelector"
            )
          );
        };
        "storageClassName" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "volumeMode" = mkOption {
          description = "PersistentVolumeMode describes how a volume is intended to be consumed, either Block or Filesystem.";
          type = (types.nullOr types.str);
        };
        "volumeName" = mkOption {
          description = "VolumeName is the binding reference to the PersistentVolume backing this claim.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "dataSource" = mkOverride 1002 null;
        "dataSourceRef" = mkOverride 1002 null;
        "resources" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "volumeMode" = mkOverride 1002 null;
        "volumeName" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecDataSource" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced.\nIf APIGroup is not specified, the specified Kind must be in the core API group.\nFor any other third-party types, APIGroup is required.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced";
          type = types.str;
        };
      };

      config = {
        "apiGroup" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecDataSourceRef" = {

      options = {
        "apiGroup" = mkOption {
          description = "APIGroup is the group for the resource being referenced.\nIf APIGroup is not specified, the specified Kind must be in the core API group.\nFor any other third-party types, APIGroup is required.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind is the type of resource being referenced";
          type = types.str;
        };
        "name" = mkOption {
          description = "Name is the name of resource being referenced";
          type = types.str;
        };
      };

      config = {
        "apiGroup" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecResourcesClaims"
                "name"
                [ "name" ]
            )
          );
          apply = attrsToList;
        };
        "limits" = mkOption {
          description = "Limits describes the maximum amount of compute resources allowed.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
        "requests" = mkOption {
          description = "Requests describes the minimum amount of compute resources required.\nIf Requests is omitted for a container, it defaults to Limits if that is explicitly specified,\notherwise to an implementation-defined value. Requests cannot exceed Limits.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/";
          type = (types.nullOr (types.attrsOf (types.either types.int types.str)));
        };
      };

      config = {
        "claims" = mkOverride 1002 null;
        "limits" = mkOverride 1002 null;
        "requests" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecResourcesClaims" = {

      options = {
        "name" = mkOption {
          description = "Name must match the name of one entry in pod.spec.resourceClaims of\nthe Pod where this field is used. It makes that resource available\ninside a container.";
          type = types.str;
        };
        "request" = mkOption {
          description = "Request is the name chosen for a request in the referenced claim.\nIf empty, everything from the claim is made available, otherwise\nonly the result of this request.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "request" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecSelectorMatchExpressions"
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
    "grafana.integreatly.org.v1beta1.GrafanaSpecPersistentVolumeClaimSpecSelectorMatchExpressions" = {

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
    "grafana.integreatly.org.v1beta1.GrafanaSpecPreferences" = {

      options = {
        "homeDashboardUid" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "homeDashboardUid" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecRoute" = {

      options = {
        "metadata" = mkOption {
          description = "ObjectMeta contains only a [subset of the fields included in k8s.io/apimachinery/pkg/apis/meta/v1.ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#objectmeta-v1-meta).";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecRouteMetadata"));
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpec"));
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecRouteMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpec" = {

      options = {
        "alternateBackends" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpecAlternateBackends"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "host" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "path" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "RoutePort defines a port mapping from a router to an endpoint in the service endpoints.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpecPort"));
        };
        "subdomain" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "tls" = mkOption {
          description = "TLSConfig defines config used to secure a route and provide termination";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpecTls"));
        };
        "to" = mkOption {
          description = "RouteTargetReference specifies the target that resolve into endpoints. Only the 'Service'\nkind is allowed. Use 'weight' field to emphasize one over others.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpecTo"));
        };
        "wildcardPolicy" = mkOption {
          description = "WildcardPolicyType indicates the type of wildcard support needed by routes.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "alternateBackends" = mkOverride 1002 null;
        "host" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "subdomain" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "to" = mkOverride 1002 null;
        "wildcardPolicy" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpecAlternateBackends" = {

      options = {
        "kind" = mkOption {
          description = "The kind of target that the route is referring to. Currently, only 'Service' is allowed";
          type = (
            types.enum [
              "Service"
              ""
            ]
          );
        };
        "name" = mkOption {
          description = "name of the service/target that is being referred to. e.g. name of the service";
          type = (types.withMinLength 1 types.str);
        };
        "weight" = mkOption {
          description = "weight as an integer between 0 and 256, default 100, that specifies the target's relative weight\nagainst other target reference objects. 0 suppresses requests to this backend.";
          type = (types.nullOr (types.withMaximum 256 (types.withMinimum 0 types.int)));
        };
      };

      config = {
        "weight" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpecPort" = {

      options = {
        "targetPort" = mkOption {
          description = "The target port on pods selected by the service this route points to.\nIf this is a string, it will be looked up as a named port in the target\nendpoints port list. Required";
          type = (types.either types.int types.str);
        };
      };

      config = { };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpecTls" = {

      options = {
        "caCertificate" = mkOption {
          description = "caCertificate provides the cert authority certificate contents";
          type = (types.nullOr types.str);
        };
        "certificate" = mkOption {
          description = "certificate provides certificate contents. This should be a single serving certificate, not a certificate\nchain. Do not include a CA certificate.";
          type = (types.nullOr types.str);
        };
        "destinationCACertificate" = mkOption {
          description = "destinationCACertificate provides the contents of the ca certificate of the final destination.  When using reencrypt\ntermination this file should be provided in order to have routers use it for health checks on the secure connection.\nIf this field is not specified, the router may provide its own destination CA and perform hostname validation using\nthe short service name (service.namespace.svc), which allows infrastructure generated certificates to automatically\nverify.";
          type = (types.nullOr types.str);
        };
        "externalCertificate" = mkOption {
          description = "externalCertificate provides certificate contents as a secret reference.\nThis should be a single serving certificate, not a certificate\nchain. Do not include a CA certificate. The secret referenced should\nbe present in the same namespace as that of the Route.\nForbidden when `certificate` is set.\nThe router service account needs to be granted with read-only access to this secret,\nplease refer to openshift docs for additional details.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpecTlsExternalCertificate"
            )
          );
        };
        "insecureEdgeTerminationPolicy" = mkOption {
          description = "insecureEdgeTerminationPolicy indicates the desired behavior for insecure connections to a route. While\neach router may make its own decisions on which ports to expose, this is normally port 80.\n\nIf a route does not specify insecureEdgeTerminationPolicy, then the default behavior is \"None\".\n\n* Allow - traffic is sent to the server on the insecure port (edge/reencrypt terminations only).\n\n* None - no traffic is allowed on the insecure port (default).\n\n* Redirect - clients are redirected to the secure port.";
          type = (
            types.nullOr (
              types.enum [
                "Allow"
                "None"
                "Redirect"
                ""
              ]
            )
          );
        };
        "key" = mkOption {
          description = "key provides key file contents";
          type = (types.nullOr types.str);
        };
        "termination" = mkOption {
          description = "termination indicates termination type.\n\n* edge - TLS termination is done by the router and http is used to communicate with the backend (default)\n* passthrough - Traffic is sent straight to the destination without the router providing TLS termination\n* reencrypt - TLS termination is done by the router and https is used to communicate with the backend\n\nNote: passthrough termination is incompatible with httpHeader actions";
          type = (
            types.enum [
              "edge"
              "reencrypt"
              "passthrough"
            ]
          );
        };
      };

      config = {
        "caCertificate" = mkOverride 1002 null;
        "certificate" = mkOverride 1002 null;
        "destinationCACertificate" = mkOverride 1002 null;
        "externalCertificate" = mkOverride 1002 null;
        "insecureEdgeTerminationPolicy" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpecTlsExternalCertificate" = {

      options = {
        "name" = mkOption {
          description = "name of the referent.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecRouteSpecTo" = {

      options = {
        "kind" = mkOption {
          description = "The kind of target that the route is referring to. Currently, only 'Service' is allowed";
          type = (
            types.enum [
              "Service"
              ""
            ]
          );
        };
        "name" = mkOption {
          description = "name of the service/target that is being referred to. e.g. name of the service";
          type = (types.withMinLength 1 types.str);
        };
        "weight" = mkOption {
          description = "weight as an integer between 0 and 256, default 100, that specifies the target's relative weight\nagainst other target reference objects. 0 suppresses requests to this backend.";
          type = (types.nullOr (types.withMaximum 256 (types.withMinimum 0 types.int)));
        };
      };

      config = {
        "weight" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecService" = {

      options = {
        "metadata" = mkOption {
          description = "ObjectMeta contains only a [subset of the fields included in k8s.io/apimachinery/pkg/apis/meta/v1.ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#objectmeta-v1-meta).";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecServiceMetadata"));
        };
        "spec" = mkOption {
          description = "ServiceSpec describes the attributes that a user creates on a service.";
          type = (types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecServiceSpec"));
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
        "spec" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecServiceAccount" = {

      options = {
        "automountServiceAccountToken" = mkOption {
          description = "";
          type = (types.nullOr types.bool);
        };
        "imagePullSecrets" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecServiceAccountImagePullSecrets"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "metadata" = mkOption {
          description = "ObjectMeta contains only a [subset of the fields included in k8s.io/apimachinery/pkg/apis/meta/v1.ObjectMeta](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#objectmeta-v1-meta).";
          type = (
            types.nullOr (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecServiceAccountMetadata")
          );
        };
        "secrets" = mkOption {
          description = "";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "grafana.integreatly.org.v1beta1.GrafanaSpecServiceAccountSecrets"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "automountServiceAccountToken" = mkOverride 1002 null;
        "imagePullSecrets" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "secrets" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecServiceAccountImagePullSecrets" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecServiceAccountMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecServiceAccountSecrets" = {

      options = {
        "apiVersion" = mkOption {
          description = "API version of the referent.";
          type = (types.nullOr types.str);
        };
        "fieldPath" = mkOption {
          description = "If referring to a piece of an object instead of an entire object, this string\nshould contain a valid JSON/Go field access statement, such as desiredState.manifest.containers[2].\nFor example, if the object reference is to a container within a pod, this would take on a value like:\n\"spec.containers{name}\" (where \"name\" refers to the name of the container that triggered\nthe event) or if no container name is specified \"spec.containers[2]\" (container with\nindex 2 in this pod). This syntax is chosen only to have some well-defined way of\nreferencing a part of an object.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "Kind of the referent.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Name of the referent.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "Namespace of the referent.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/";
          type = (types.nullOr types.str);
        };
        "resourceVersion" = mkOption {
          description = "Specific resourceVersion to which this reference is made, if any.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency";
          type = (types.nullOr types.str);
        };
        "uid" = mkOption {
          description = "UID of the referent.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#uids";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "fieldPath" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "resourceVersion" = mkOverride 1002 null;
        "uid" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecServiceMetadata" = {

      options = {
        "annotations" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "labels" = mkOption {
          description = "";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "annotations" = mkOverride 1002 null;
        "labels" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecServiceSpec" = {

      options = {
        "allocateLoadBalancerNodePorts" = mkOption {
          description = "allocateLoadBalancerNodePorts defines if NodePorts will be automatically\nallocated for services with type LoadBalancer.  Default is \"true\". It\nmay be set to \"false\" if the cluster load-balancer does not rely on\nNodePorts.  If the caller requests specific NodePorts (by specifying a\nvalue), those requests will be respected, regardless of this field.\nThis field may only be set for services with type LoadBalancer and will\nbe cleared if the type is changed to any other type.";
          type = (types.nullOr types.bool);
        };
        "clusterIP" = mkOption {
          description = "clusterIP is the IP address of the service and is usually assigned\nrandomly. If an address is specified manually, is in-range (as per\nsystem configuration), and is not in use, it will be allocated to the\nservice; otherwise creation of the service will fail. This field may not\nbe changed through updates unless the type field is also being changed\nto ExternalName (which requires this field to be blank) or the type\nfield is being changed from ExternalName (in which case this field may\noptionally be specified, as describe above).  Valid values are \"None\",\nempty string (\"\"), or a valid IP address. Setting this to \"None\" makes a\n\"headless service\" (no virtual IP), which is useful when direct endpoint\nconnections are preferred and proxying is not required.  Only applies to\ntypes ClusterIP, NodePort, and LoadBalancer. If this field is specified\nwhen creating a Service of type ExternalName, creation will fail. This\nfield will be wiped when updating a Service to type ExternalName.\nMore info: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies";
          type = (types.nullOr types.str);
        };
        "clusterIPs" = mkOption {
          description = "ClusterIPs is a list of IP addresses assigned to this service, and are\nusually assigned randomly.  If an address is specified manually, is\nin-range (as per system configuration), and is not in use, it will be\nallocated to the service; otherwise creation of the service will fail.\nThis field may not be changed through updates unless the type field is\nalso being changed to ExternalName (which requires this field to be\nempty) or the type field is being changed from ExternalName (in which\ncase this field may optionally be specified, as describe above).  Valid\nvalues are \"None\", empty string (\"\"), or a valid IP address.  Setting\nthis to \"None\" makes a \"headless service\" (no virtual IP), which is\nuseful when direct endpoint connections are preferred and proxying is\nnot required.  Only applies to types ClusterIP, NodePort, and\nLoadBalancer. If this field is specified when creating a Service of type\nExternalName, creation will fail. This field will be wiped when updating\na Service to type ExternalName.  If this field is not specified, it will\nbe initialized from the clusterIP field.  If this field is specified,\nclients must ensure that clusterIPs[0] and clusterIP have the same\nvalue.\n\nThis field may hold a maximum of two entries (dual-stack IPs, in either order).\nThese IPs must correspond to the values of the ipFamilies field. Both\nclusterIPs and ipFamilies are governed by the ipFamilyPolicy field.\nMore info: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies";
          type = (types.nullOr (types.listOf types.str));
        };
        "externalIPs" = mkOption {
          description = "externalIPs is a list of IP addresses for which nodes in the cluster\nwill also accept traffic for this service.  These IPs are not managed by\nKubernetes.  The user is responsible for ensuring that traffic arrives\nat a node with this IP.  A common example is external load-balancers\nthat are not part of the Kubernetes system.";
          type = (types.nullOr (types.listOf types.str));
        };
        "externalName" = mkOption {
          description = "externalName is the external reference that discovery mechanisms will\nreturn as an alias for this service (e.g. a DNS CNAME record). No\nproxying will be involved.  Must be a lowercase RFC-1123 hostname\n(https://tools.ietf.org/html/rfc1123) and requires `type` to be \"ExternalName\".";
          type = (types.nullOr types.str);
        };
        "externalTrafficPolicy" = mkOption {
          description = "externalTrafficPolicy describes how nodes distribute service traffic they\nreceive on one of the Service's \"externally-facing\" addresses (NodePorts,\nExternalIPs, and LoadBalancer IPs). If set to \"Local\", the proxy will configure\nthe service in a way that assumes that external load balancers will take care\nof balancing the service traffic between nodes, and so each node will deliver\ntraffic only to the node-local endpoints of the service, without masquerading\nthe client source IP. (Traffic mistakenly sent to a node with no endpoints will\nbe dropped.) The default value, \"Cluster\", uses the standard behavior of\nrouting to all endpoints evenly (possibly modified by topology and other\nfeatures). Note that traffic sent to an External IP or LoadBalancer IP from\nwithin the cluster will always get \"Cluster\" semantics, but clients sending to\na NodePort from within the cluster may need to take traffic policy into account\nwhen picking a node.";
          type = (types.nullOr types.str);
        };
        "healthCheckNodePort" = mkOption {
          description = "healthCheckNodePort specifies the healthcheck nodePort for the service.\nThis only applies when type is set to LoadBalancer and\nexternalTrafficPolicy is set to Local. If a value is specified, is\nin-range, and is not in use, it will be used.  If not specified, a value\nwill be automatically allocated.  External systems (e.g. load-balancers)\ncan use this port to determine if a given node holds endpoints for this\nservice or not.  If this field is specified when creating a Service\nwhich does not need it, creation will fail. This field will be wiped\nwhen updating a Service to no longer need it (e.g. changing type).\nThis field cannot be updated once set.";
          type = (types.nullOr types.int);
        };
        "internalTrafficPolicy" = mkOption {
          description = "InternalTrafficPolicy describes how nodes distribute service traffic they\nreceive on the ClusterIP. If set to \"Local\", the proxy will assume that pods\nonly want to talk to endpoints of the service on the same node as the pod,\ndropping the traffic if there are no local endpoints. The default value,\n\"Cluster\", uses the standard behavior of routing to all endpoints evenly\n(possibly modified by topology and other features).";
          type = (types.nullOr types.str);
        };
        "ipFamilies" = mkOption {
          description = "IPFamilies is a list of IP families (e.g. IPv4, IPv6) assigned to this\nservice. This field is usually assigned automatically based on cluster\nconfiguration and the ipFamilyPolicy field. If this field is specified\nmanually, the requested family is available in the cluster,\nand ipFamilyPolicy allows it, it will be used; otherwise creation of\nthe service will fail. This field is conditionally mutable: it allows\nfor adding or removing a secondary IP family, but it does not allow\nchanging the primary IP family of the Service. Valid values are \"IPv4\"\nand \"IPv6\".  This field only applies to Services of types ClusterIP,\nNodePort, and LoadBalancer, and does apply to \"headless\" services.\nThis field will be wiped when updating a Service to type ExternalName.\n\nThis field may hold a maximum of two entries (dual-stack families, in\neither order).  These families must correspond to the values of the\nclusterIPs field, if specified. Both clusterIPs and ipFamilies are\ngoverned by the ipFamilyPolicy field.";
          type = (types.nullOr (types.listOf types.str));
        };
        "ipFamilyPolicy" = mkOption {
          description = "IPFamilyPolicy represents the dual-stack-ness requested or required by\nthis Service. If there is no value provided, then this field will be set\nto SingleStack. Services can be \"SingleStack\" (a single IP family),\n\"PreferDualStack\" (two IP families on dual-stack configured clusters or\na single IP family on single-stack clusters), or \"RequireDualStack\"\n(two IP families on dual-stack configured clusters, otherwise fail). The\nipFamilies and clusterIPs fields depend on the value of this field. This\nfield will be wiped when updating a service to type ExternalName.";
          type = (types.nullOr types.str);
        };
        "loadBalancerClass" = mkOption {
          description = "loadBalancerClass is the class of the load balancer implementation this Service belongs to.\nIf specified, the value of this field must be a label-style identifier, with an optional prefix,\ne.g. \"internal-vip\" or \"example.com/internal-vip\". Unprefixed names are reserved for end-users.\nThis field can only be set when the Service type is 'LoadBalancer'. If not set, the default load\nbalancer implementation is used, today this is typically done through the cloud provider integration,\nbut should apply for any default implementation. If set, it is assumed that a load balancer\nimplementation is watching for Services with a matching class. Any default load balancer\nimplementation (e.g. cloud providers) should ignore Services that set this field.\nThis field can only be set when creating or updating a Service to type 'LoadBalancer'.\nOnce set, it can not be changed. This field will be wiped when a service is updated to a non 'LoadBalancer' type.";
          type = (types.nullOr types.str);
        };
        "loadBalancerIP" = mkOption {
          description = "Only applies to Service Type: LoadBalancer.\nThis feature depends on whether the underlying cloud-provider supports specifying\nthe loadBalancerIP when a load balancer is created.\nThis field will be ignored if the cloud-provider does not support the feature.\nDeprecated: This field was under-specified and its meaning varies across implementations.\nUsing it is non-portable and it may not support dual-stack.\nUsers are encouraged to use implementation-specific annotations when available.";
          type = (types.nullOr types.str);
        };
        "loadBalancerSourceRanges" = mkOption {
          description = "If specified and supported by the platform, this will restrict traffic through the cloud-provider\nload-balancer will be restricted to the specified client IPs. This field will be ignored if the\ncloud-provider does not support the feature.\"\nMore info: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/";
          type = (types.nullOr (types.listOf types.str));
        };
        "ports" = mkOption {
          description = "The list of ports that are exposed by this service.\nMore info: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "grafana.integreatly.org.v1beta1.GrafanaSpecServiceSpecPorts"
                "name"
                [
                  "port"
                  "protocol"
                ]
            )
          );
          apply = attrsToList;
        };
        "publishNotReadyAddresses" = mkOption {
          description = "publishNotReadyAddresses indicates that any agent which deals with endpoints for this\nService should disregard any indications of ready/not-ready.\nThe primary use case for setting this field is for a StatefulSet's Headless Service to\npropagate SRV DNS records for its Pods for the purpose of peer discovery.\nThe Kubernetes controllers that generate Endpoints and EndpointSlice resources for\nServices interpret this to mean that all endpoints are considered \"ready\" even if the\nPods themselves are not. Agents which consume only Kubernetes generated endpoints\nthrough the Endpoints or EndpointSlice resources can safely assume this behavior.";
          type = (types.nullOr types.bool);
        };
        "selector" = mkOption {
          description = "Route service traffic to pods with label keys and values matching this\nselector. If empty or not present, the service is assumed to have an\nexternal process managing its endpoints, which Kubernetes will not\nmodify. Only applies to types ClusterIP, NodePort, and LoadBalancer.\nIgnored if type is ExternalName.\nMore info: https://kubernetes.io/docs/concepts/services-networking/service/";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "sessionAffinity" = mkOption {
          description = "Supports \"ClientIP\" and \"None\". Used to maintain session affinity.\nEnable client IP based session affinity.\nMust be ClientIP or None.\nDefaults to None.\nMore info: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies";
          type = (types.nullOr types.str);
        };
        "sessionAffinityConfig" = mkOption {
          description = "sessionAffinityConfig contains the configurations of session affinity.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecServiceSpecSessionAffinityConfig"
            )
          );
        };
        "trafficDistribution" = mkOption {
          description = "TrafficDistribution offers a way to express preferences for how traffic\nis distributed to Service endpoints. Implementations can use this field\nas a hint, but are not required to guarantee strict adherence. If the\nfield is not set, the implementation will apply its default routing\nstrategy. If set to \"PreferClose\", implementations should prioritize\nendpoints that are in the same zone.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type determines how the Service is exposed. Defaults to ClusterIP. Valid\noptions are ExternalName, ClusterIP, NodePort, and LoadBalancer.\n\"ClusterIP\" allocates a cluster-internal IP address for load-balancing\nto endpoints. Endpoints are determined by the selector or if that is not\nspecified, by manual construction of an Endpoints object or\nEndpointSlice objects. If clusterIP is \"None\", no virtual IP is\nallocated and the endpoints are published as a set of endpoints rather\nthan a virtual IP.\n\"NodePort\" builds on ClusterIP and allocates a port on every node which\nroutes to the same endpoints as the clusterIP.\n\"LoadBalancer\" builds on NodePort and creates an external load-balancer\n(if supported in the current cloud) which routes to the same endpoints\nas the clusterIP.\n\"ExternalName\" aliases this service to the specified externalName.\nSeveral other fields do not apply to ExternalName services.\nMore info: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "allocateLoadBalancerNodePorts" = mkOverride 1002 null;
        "clusterIP" = mkOverride 1002 null;
        "clusterIPs" = mkOverride 1002 null;
        "externalIPs" = mkOverride 1002 null;
        "externalName" = mkOverride 1002 null;
        "externalTrafficPolicy" = mkOverride 1002 null;
        "healthCheckNodePort" = mkOverride 1002 null;
        "internalTrafficPolicy" = mkOverride 1002 null;
        "ipFamilies" = mkOverride 1002 null;
        "ipFamilyPolicy" = mkOverride 1002 null;
        "loadBalancerClass" = mkOverride 1002 null;
        "loadBalancerIP" = mkOverride 1002 null;
        "loadBalancerSourceRanges" = mkOverride 1002 null;
        "ports" = mkOverride 1002 null;
        "publishNotReadyAddresses" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "sessionAffinity" = mkOverride 1002 null;
        "sessionAffinityConfig" = mkOverride 1002 null;
        "trafficDistribution" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecServiceSpecPorts" = {

      options = {
        "appProtocol" = mkOption {
          description = "The application protocol for this port.\nThis is used as a hint for implementations to offer richer behavior for protocols that they understand.\nThis field follows standard Kubernetes label syntax.\nValid values are either:\n\n* Un-prefixed protocol names - reserved for IANA standard service names (as per\nRFC-6335 and https://www.iana.org/assignments/service-names).\n\n* Kubernetes-defined prefixed names:\n  * 'kubernetes.io/h2c' - HTTP/2 prior knowledge over cleartext as described in https://www.rfc-editor.org/rfc/rfc9113.html#name-starting-http-2-with-prior-\n  * 'kubernetes.io/ws'  - WebSocket over cleartext as described in https://www.rfc-editor.org/rfc/rfc6455\n  * 'kubernetes.io/wss' - WebSocket over TLS as described in https://www.rfc-editor.org/rfc/rfc6455\n\n* Other protocols should use implementation-defined prefixed names such as\nmycompany.com/my-custom-protocol.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "The name of this port within the service. This must be a DNS_LABEL.\nAll ports within a ServiceSpec must have unique names. When considering\nthe endpoints for a Service, this must match the 'name' field in the\nEndpointPort.\nOptional if only one ServicePort is defined on this service.";
          type = (types.nullOr types.str);
        };
        "nodePort" = mkOption {
          description = "The port on each node on which this service is exposed when type is\nNodePort or LoadBalancer.  Usually assigned by the system. If a value is\nspecified, in-range, and not in use it will be used, otherwise the\noperation will fail.  If not specified, a port will be allocated if this\nService requires one.  If this field is specified when creating a\nService which does not need it, creation will fail. This field will be\nwiped when updating a Service to no longer need it (e.g. changing type\nfrom NodePort to ClusterIP).\nMore info: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport";
          type = (types.nullOr types.int);
        };
        "port" = mkOption {
          description = "The port that will be exposed by this service.";
          type = types.int;
        };
        "protocol" = mkOption {
          description = "The IP protocol for this port. Supports \"TCP\", \"UDP\", and \"SCTP\".\nDefault is TCP.";
          type = (types.nullOr types.str);
        };
        "targetPort" = mkOption {
          description = "Number or name of the port to access on the pods targeted by the service.\nNumber must be in the range 1 to 65535. Name must be an IANA_SVC_NAME.\nIf this is a string, it will be looked up as a named port in the\ntarget Pod's container ports. If this is not specified, the value\nof the 'port' field is used (an identity map).\nThis field is ignored for services with clusterIP=None, and should be\nomitted or set equal to the 'port' field.\nMore info: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service";
          type = (types.nullOr (types.either types.int types.str));
        };
      };

      config = {
        "appProtocol" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "nodePort" = mkOverride 1002 null;
        "protocol" = mkOverride 1002 null;
        "targetPort" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecServiceSpecSessionAffinityConfig" = {

      options = {
        "clientIP" = mkOption {
          description = "clientIP contains the configurations of Client IP based session affinity.";
          type = (
            types.nullOr (
              submoduleOf "grafana.integreatly.org.v1beta1.GrafanaSpecServiceSpecSessionAffinityConfigClientIP"
            )
          );
        };
      };

      config = {
        "clientIP" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaSpecServiceSpecSessionAffinityConfigClientIP" = {

      options = {
        "timeoutSeconds" = mkOption {
          description = "timeoutSeconds specifies the seconds of ClientIP type session sticky time.\nThe value must be >0 && <=86400(for 1 day) if ServiceAffinity == \"ClientIP\".\nDefault value is 10800(for 3 hours).";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "timeoutSeconds" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaStatus" = {

      options = {
        "adminUrl" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "alertRuleGroups" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "grafana.integreatly.org.v1beta1.GrafanaStatusConditions"))
          );
        };
        "contactPoints" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "dashboards" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "datasources" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "folders" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "lastMessage" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "libraryPanels" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "manifests" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "muteTimings" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "notificationTemplates" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "replicas" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "selector" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "serviceaccounts" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
        "stage" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "stageStatus" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "version" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "adminUrl" = mkOverride 1002 null;
        "alertRuleGroups" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "contactPoints" = mkOverride 1002 null;
        "dashboards" = mkOverride 1002 null;
        "datasources" = mkOverride 1002 null;
        "folders" = mkOverride 1002 null;
        "lastMessage" = mkOverride 1002 null;
        "libraryPanels" = mkOverride 1002 null;
        "manifests" = mkOverride 1002 null;
        "muteTimings" = mkOverride 1002 null;
        "notificationTemplates" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "selector" = mkOverride 1002 null;
        "serviceaccounts" = mkOverride 1002 null;
        "stage" = mkOverride 1002 null;
        "stageStatus" = mkOverride 1002 null;
        "version" = mkOverride 1002 null;
      };

    };
    "grafana.integreatly.org.v1beta1.GrafanaStatusConditions" = {

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
      "grafana.integreatly.org"."v1beta1"."Grafana" = mkOption {
        description = "Grafana is the Schema for the grafanas API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.Grafana" "grafanas" "Grafana"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaAlertRuleGroup" = mkOption {
        description = "GrafanaAlertRuleGroup is the Schema for the grafanaalertrulegroups API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroup"
              "grafanaalertrulegroups"
              "GrafanaAlertRuleGroup"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaContactPoint" = mkOption {
        description = "GrafanaContactPoint is the Schema for the grafanacontactpoints API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaContactPoint" "grafanacontactpoints"
              "GrafanaContactPoint"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaDashboard" = mkOption {
        description = "GrafanaDashboard is the Schema for the grafanadashboards API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaDashboard" "grafanadashboards"
              "GrafanaDashboard"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaDatasource" = mkOption {
        description = "GrafanaDatasource is the Schema for the grafanadatasources API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaDatasource" "grafanadatasources"
              "GrafanaDatasource"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaFolder" = mkOption {
        description = "GrafanaFolder is the Schema for the grafanafolders API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaFolder" "grafanafolders"
              "GrafanaFolder"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaLibraryPanel" = mkOption {
        description = "GrafanaLibraryPanel is the Schema for the grafanalibrarypanels API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaLibraryPanel" "grafanalibrarypanels"
              "GrafanaLibraryPanel"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaManifest" = mkOption {
        description = "GrafanaManifest is the Schema for the grafana manifests";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaManifest" "grafanamanifests"
              "GrafanaManifest"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaMuteTiming" = mkOption {
        description = "GrafanaMuteTiming is the Schema for the GrafanaMuteTiming API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaMuteTiming" "grafanamutetimings"
              "GrafanaMuteTiming"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaNotificationPolicy" = mkOption {
        description = "GrafanaNotificationPolicy is the Schema for the GrafanaNotificationPolicy API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicy"
              "grafananotificationpolicies"
              "GrafanaNotificationPolicy"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaNotificationPolicyRoute" = mkOption {
        description = "GrafanaNotificationPolicyRoute is the Schema for the grafananotificationpolicyroutes API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRoute"
              "grafananotificationpolicyroutes"
              "GrafanaNotificationPolicyRoute"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaNotificationTemplate" = mkOption {
        description = "GrafanaNotificationTemplate is the Schema for the GrafanaNotificationTemplate API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplate"
              "grafananotificationtemplates"
              "GrafanaNotificationTemplate"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafana.integreatly.org"."v1beta1"."GrafanaServiceAccount" = mkOption {
        description = "GrafanaServiceAccount is the Schema for the grafanaserviceaccounts API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaServiceAccount"
              "grafanaserviceaccounts"
              "GrafanaServiceAccount"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };

    }
    // {
      "grafanas" = mkOption {
        description = "Grafana is the Schema for the grafanas API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.Grafana" "grafanas" "Grafana"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaAlertRuleGroups" = mkOption {
        description = "GrafanaAlertRuleGroup is the Schema for the grafanaalertrulegroups API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaAlertRuleGroup"
              "grafanaalertrulegroups"
              "GrafanaAlertRuleGroup"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaContactPoints" = mkOption {
        description = "GrafanaContactPoint is the Schema for the grafanacontactpoints API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaContactPoint" "grafanacontactpoints"
              "GrafanaContactPoint"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaDashboards" = mkOption {
        description = "GrafanaDashboard is the Schema for the grafanadashboards API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaDashboard" "grafanadashboards"
              "GrafanaDashboard"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaDatasources" = mkOption {
        description = "GrafanaDatasource is the Schema for the grafanadatasources API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaDatasource" "grafanadatasources"
              "GrafanaDatasource"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaFolders" = mkOption {
        description = "GrafanaFolder is the Schema for the grafanafolders API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaFolder" "grafanafolders"
              "GrafanaFolder"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaLibraryPanels" = mkOption {
        description = "GrafanaLibraryPanel is the Schema for the grafanalibrarypanels API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaLibraryPanel" "grafanalibrarypanels"
              "GrafanaLibraryPanel"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaManifests" = mkOption {
        description = "GrafanaManifest is the Schema for the grafana manifests";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaManifest" "grafanamanifests"
              "GrafanaManifest"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaMuteTimings" = mkOption {
        description = "GrafanaMuteTiming is the Schema for the GrafanaMuteTiming API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaMuteTiming" "grafanamutetimings"
              "GrafanaMuteTiming"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaNotificationPolicies" = mkOption {
        description = "GrafanaNotificationPolicy is the Schema for the GrafanaNotificationPolicy API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicy"
              "grafananotificationpolicies"
              "GrafanaNotificationPolicy"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaNotificationPolicyRoutes" = mkOption {
        description = "GrafanaNotificationPolicyRoute is the Schema for the grafananotificationpolicyroutes API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaNotificationPolicyRoute"
              "grafananotificationpolicyroutes"
              "GrafanaNotificationPolicyRoute"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaNotificationTemplates" = mkOption {
        description = "GrafanaNotificationTemplate is the Schema for the GrafanaNotificationTemplate API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaNotificationTemplate"
              "grafananotificationtemplates"
              "GrafanaNotificationTemplate"
              "grafana.integreatly.org"
              "v1beta1"
          )
        );
        default = { };
      };
      "grafanaServiceAccounts" = mkOption {
        description = "GrafanaServiceAccount is the Schema for the grafanaserviceaccounts API";
        type = (
          types.attrsOf (
            submoduleForDefinition "grafana.integreatly.org.v1beta1.GrafanaServiceAccount"
              "grafanaserviceaccounts"
              "GrafanaServiceAccount"
              "grafana.integreatly.org"
              "v1beta1"
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
        name = "grafanas";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "Grafana";
        attrName = "grafanas";
      }
      {
        name = "grafanaalertrulegroups";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaAlertRuleGroup";
        attrName = "grafanaAlertRuleGroups";
      }
      {
        name = "grafanacontactpoints";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaContactPoint";
        attrName = "grafanaContactPoints";
      }
      {
        name = "grafanadashboards";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaDashboard";
        attrName = "grafanaDashboards";
      }
      {
        name = "grafanadatasources";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaDatasource";
        attrName = "grafanaDatasources";
      }
      {
        name = "grafanafolders";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaFolder";
        attrName = "grafanaFolders";
      }
      {
        name = "grafanalibrarypanels";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaLibraryPanel";
        attrName = "grafanaLibraryPanels";
      }
      {
        name = "grafanamanifests";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaManifest";
        attrName = "grafanaManifests";
      }
      {
        name = "grafanamutetimings";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaMuteTiming";
        attrName = "grafanaMuteTimings";
      }
      {
        name = "grafananotificationpolicies";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaNotificationPolicy";
        attrName = "grafanaNotificationPolicies";
      }
      {
        name = "grafananotificationpolicyroutes";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaNotificationPolicyRoute";
        attrName = "grafanaNotificationPolicyRoutes";
      }
      {
        name = "grafananotificationtemplates";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaNotificationTemplate";
        attrName = "grafanaNotificationTemplates";
      }
      {
        name = "grafanaserviceaccounts";
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaServiceAccount";
        attrName = "grafanaServiceAccounts";
      }
    ];

    resources = {
      "grafana.integreatly.org"."v1beta1"."Grafana" = mkAliasDefinitions options.resources."grafanas";
      "grafana.integreatly.org"."v1beta1"."GrafanaAlertRuleGroup" =
        mkAliasDefinitions
          options.resources."grafanaAlertRuleGroups";
      "grafana.integreatly.org"."v1beta1"."GrafanaContactPoint" =
        mkAliasDefinitions
          options.resources."grafanaContactPoints";
      "grafana.integreatly.org"."v1beta1"."GrafanaDashboard" =
        mkAliasDefinitions
          options.resources."grafanaDashboards";
      "grafana.integreatly.org"."v1beta1"."GrafanaDatasource" =
        mkAliasDefinitions
          options.resources."grafanaDatasources";
      "grafana.integreatly.org"."v1beta1"."GrafanaFolder" =
        mkAliasDefinitions
          options.resources."grafanaFolders";
      "grafana.integreatly.org"."v1beta1"."GrafanaLibraryPanel" =
        mkAliasDefinitions
          options.resources."grafanaLibraryPanels";
      "grafana.integreatly.org"."v1beta1"."GrafanaManifest" =
        mkAliasDefinitions
          options.resources."grafanaManifests";
      "grafana.integreatly.org"."v1beta1"."GrafanaMuteTiming" =
        mkAliasDefinitions
          options.resources."grafanaMuteTimings";
      "grafana.integreatly.org"."v1beta1"."GrafanaNotificationPolicy" =
        mkAliasDefinitions
          options.resources."grafanaNotificationPolicies";
      "grafana.integreatly.org"."v1beta1"."GrafanaNotificationPolicyRoute" =
        mkAliasDefinitions
          options.resources."grafanaNotificationPolicyRoutes";
      "grafana.integreatly.org"."v1beta1"."GrafanaNotificationTemplate" =
        mkAliasDefinitions
          options.resources."grafanaNotificationTemplates";
      "grafana.integreatly.org"."v1beta1"."GrafanaServiceAccount" =
        mkAliasDefinitions
          options.resources."grafanaServiceAccounts";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "Grafana";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaAlertRuleGroup";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaContactPoint";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaDashboard";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaDatasource";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaFolder";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaLibraryPanel";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaManifest";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaMuteTiming";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaNotificationPolicy";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaNotificationPolicyRoute";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaNotificationTemplate";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "grafana.integreatly.org";
        version = "v1beta1";
        kind = "GrafanaServiceAccount";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
