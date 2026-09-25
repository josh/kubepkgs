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
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgrade" = {

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
          description = "KubernetesUpgradeSpec defines the desired state of KubernetesUpgrade";
          type = (types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpec"));
        };
        "status" = mkOption {
          description = "KubernetesUpgradeStatus defines the observed state of KubernetesUpgrade";
          type = (types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeStatus"));
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
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpec" = {

      options = {
        "healthChecks" = mkOption {
          description = "HealthChecks defines a list of CEL-based health checks to perform before the upgrade";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecHealthChecks"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "kubernetes" = mkOption {
          description = "Kubernetes defines the target Kubernetes configuration";
          type = (submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecKubernetes");
        };
        "maintenance" = mkOption {
          description = "Maintenance configuration behavior for upgrade operations";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecMaintenance")
          );
        };
        "talosctl" = mkOption {
          description = "Talosctl specifies the talosctl configuration for upgrade operations";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecTalosctl")
          );
        };
      };

      config = {
        "healthChecks" = mkOverride 1002 null;
        "maintenance" = mkOverride 1002 null;
        "talosctl" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecHealthChecks" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion of the resource to check";
          type = types.str;
        };
        "description" = mkOption {
          description = "Description of what this check validates (for status/logging)";
          type = (types.nullOr types.str);
        };
        "expr" = mkOption {
          description = "CEL expression that must evaluate to true for the check to pass\nThe resource object is available as 'object' and status as 'status'";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind of the resource to check";
          type = types.str;
        };
        "labelSelector" = mkOption {
          description = "LabelSelector selects resources to check when name is empty";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecHealthChecksLabelSelector"
            )
          );
        };
        "name" = mkOption {
          description = "Name of the specific resource (optional, if empty checks all resources of this kind)";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "Namespace of the resource (optional, for namespaced resources)";
          type = (types.nullOr types.str);
        };
        "timeout" = mkOption {
          description = "Timeout for this health check";
          type = (types.nullOr (types.withMinLength 2 types.str));
        };
      };

      config = {
        "description" = mkOverride 1002 null;
        "labelSelector" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecHealthChecksLabelSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecHealthChecksLabelSelectorMatchExpressions"
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
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecHealthChecksLabelSelectorMatchExpressions" =
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
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecKubernetes" = {

      options = {
        "endpoint" = mkOption {
          description = "Endpoint overrides the Kubernetes API URL the upgrade Job queries.\nDefaults to the in-cluster apiserver ClusterIP, which avoids CoreDNS.";
          type = (types.nullOr types.str);
        };
        "imageRepository" = mkOption {
          description = "ImageRepository overrides the registry+path prefix for Kubernetes component\nimages. When set, each component (kube-apiserver, kube-controller-manager,\nkube-scheduler, kube-proxy, kubelet) is pulled from\n\"<imageRepository>/<component>:<version>\".";
          type = (types.nullOr types.str);
        };
        "version" = mkOption {
          description = "Version is the target Kubernetes version to upgrade to (e.g., \"v1.34.0\")";
          type = types.str;
        };
      };

      config = {
        "endpoint" = mkOverride 1002 null;
        "imageRepository" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecMaintenance" = {

      options = {
        "windows" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecMaintenanceWindows"
              )
            )
          );
        };
      };

      config = {
        "windows" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecMaintenanceWindows" = {

      options = {
        "duration" = mkOption {
          description = "How long the window stays open (e.g., \"4h\", \"2h30m\")";
          type = types.str;
        };
        "start" = mkOption {
          description = "Cron expression (5-field): minute hour day-of-month month day-of-week";
          type = (types.withMinLength 9 types.str);
        };
        "timezone" = mkOption {
          description = "IANA timezone (e.g., \"UTC\", \"Europe/Paris\")";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "timezone" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecTalosctl" = {

      options = {
        "image" = mkOption {
          description = "Image specifies the talosctl container image";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecTalosctlImage")
          );
        };
      };

      config = {
        "image" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeSpecTalosctlImage" = {

      options = {
        "pullPolicy" = mkOption {
          description = "PullPolicy describes a policy for if/when to pull a container image";
          type = (
            types.nullOr (
              types.enum [
                "Always"
                "Never"
                "IfNotPresent"
              ]
            )
          );
        };
        "repository" = mkOption {
          description = "Repository is the talosctl container image repository";
          type = (types.nullOr types.str);
        };
        "tag" = mkOption {
          description = "Tag is the talosctl container image tag\nIf not specified, defaults to the target version";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "pullPolicy" = mkOverride 1002 null;
        "repository" = mkOverride 1002 null;
        "tag" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeStatus" = {

      options = {
        "completedAt" = mkOption {
          description = "CompletedAt is the time the upgrade reached a terminal phase";
          type = (types.nullOr types.str);
        };
        "completionCycles" = mkOption {
          description = "CompletionCycles counts Completed→Pending re-entries: a completed run\nre-opened because a node still lags the target version. Bounds restart\nloops; reset by spec changes and the reset annotation.";
          type = (types.nullOr types.int);
        };
        "conditions" = mkOption {
          description = "Conditions report the upgrade's \"Progressing\" and \"Ready\" status.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeStatusConditions")
            )
          );
        };
        "controllerNode" = mkOption {
          description = "ControllerNode is the controller node being used for the upgrade";
          type = (types.nullOr types.str);
        };
        "currentVersion" = mkOption {
          description = "CurrentVersion is the current Kubernetes version detected in the cluster";
          type = (types.nullOr types.str);
        };
        "history" = mkOption {
          description = "History records past version transitions on this CR, newest first";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeStatusHistory")
            )
          );
        };
        "jobName" = mkOption {
          description = "JobName is the name of the job handling the upgrade";
          type = (types.nullOr types.str);
        };
        "lastError" = mkOption {
          description = "LastError contains the last error message";
          type = (types.nullOr types.str);
        };
        "lastUpdated" = mkOption {
          description = "LastUpdated timestamp of last status update";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "Message provides details about the current state";
          type = (types.nullOr types.str);
        };
        "nextMaintenanceWindow" = mkOption {
          description = "NextMaintenanceWindow reflect the next time a maintenance can happen";
          type = (types.nullOr types.str);
        };
        "observedGeneration" = mkOption {
          description = "ObservedGeneration reflects the generation of the most recently observed spec";
          type = (types.nullOr types.int);
        };
        "phase" = mkOption {
          description = "Phase represents the current phase of the upgrade";
          type = (
            types.nullOr (
              types.enum [
                "Pending"
                "HealthChecking"
                "PreHook"
                "Draining"
                "Upgrading"
                "Rebooting"
                "PostHook"
                "Completed"
                "Failed"
                "MaintenanceWindow"
              ]
            )
          );
        };
        "retries" = mkOption {
          description = "Retries is the number of times the upgrade was attempted";
          type = (types.nullOr (types.withMinimum 0 types.int));
        };
        "startedAt" = mkOption {
          description = "StartedAt is the time the current upgrade attempt began";
          type = (types.nullOr types.str);
        };
        "targetVersion" = mkOption {
          description = "TargetVersion is the target version from the spec";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "completedAt" = mkOverride 1002 null;
        "completionCycles" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "controllerNode" = mkOverride 1002 null;
        "currentVersion" = mkOverride 1002 null;
        "history" = mkOverride 1002 null;
        "jobName" = mkOverride 1002 null;
        "lastError" = mkOverride 1002 null;
        "lastUpdated" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "nextMaintenanceWindow" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
        "retries" = mkOverride 1002 null;
        "startedAt" = mkOverride 1002 null;
        "targetVersion" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeStatusConditions" = {

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
    "tuppr.home-operations.com.v1alpha1.KubernetesUpgradeStatusHistory" = {

      options = {
        "completedAt" = mkOption {
          description = "CompletedAt is when the run reached its terminal phase";
          type = types.str;
        };
        "fromVersion" = mkOption {
          description = "FromVersion is the cluster version detected at the start of the run";
          type = (types.nullOr types.str);
        };
        "lastError" = mkOption {
          description = "LastError is the final error message when Phase is Failed";
          type = (types.nullOr types.str);
        };
        "phase" = mkOption {
          description = "Phase is the terminal phase reached (Completed or Failed)";
          type = (
            types.enum [
              "Pending"
              "HealthChecking"
              "PreHook"
              "Draining"
              "Upgrading"
              "Rebooting"
              "PostHook"
              "Completed"
              "Failed"
              "MaintenanceWindow"
            ]
          );
        };
        "retries" = mkOption {
          description = "Retries is the number of retries recorded during the run";
          type = (types.nullOr (types.withMinimum 0 types.int));
        };
        "startedAt" = mkOption {
          description = "StartedAt is when the run began";
          type = types.str;
        };
        "toVersion" = mkOption {
          description = "ToVersion is the spec-target version at the time of completion";
          type = types.str;
        };
      };

      config = {
        "fromVersion" = mkOverride 1002 null;
        "lastError" = mkOverride 1002 null;
        "retries" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgrade" = {

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
          description = "TalosUpgradeSpec defines the desired state of TalosUpgrade";
          type = (types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpec"));
        };
        "status" = mkOption {
          description = "TalosUpgradeStatus defines the observed state of TalosUpgrade";
          type = (types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatus"));
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpec" = {

      options = {
        "drain" = mkOption {
          description = "Drain configuration for the node prior to upgrade.\nDeprecated: Use Talos policy drain configuration instead.";
          type = (types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecDrain"));
        };
        "healthChecks" = mkOption {
          description = "HealthChecks defines a list of CEL-based health checks to perform before each node upgrade";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHealthChecks"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "hooks" = mkOption {
          description = "Hooks configures pre/post-upgrade Jobs (e.g. `ceph osd set/unset noout`).";
          type = (types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooks"));
        };
        "maintenance" = mkOption {
          description = "Maintenance configuration behavior for upgrade operations";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecMaintenance")
          );
        };
        "nodeSelector" = mkOption {
          description = "NodeSelector defines which nodes should be included in this upgrade.";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecNodeSelector")
          );
        };
        "parallelism" = mkOption {
          description = "Parallelism is the number of nodes to upgrade concurrently in each batch.\nDefaults to 1 (sequential upgrades). Must be >= 1 and <= the number of matching nodes.";
          type = (types.nullOr (types.withMinimum 1 types.int));
        };
        "policy" = mkOption {
          description = "Policy configures upgrade behavior";
          type = (types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecPolicy"));
        };
        "silences" = mkOption {
          description = "Silences are Alertmanager silences held while this upgrade runs, one per\nentry. Requires the operator-level Alertmanager connection (Helm\n`silences.*`).";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecSilences")
            )
          );
        };
        "talos" = mkOption {
          description = "Talos specifies the talos configuration for upgrade operations";
          type = (types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecTalos"));
        };
        "talosctl" = mkOption {
          description = "Talosctl specifies the talosctl configuration for upgrade operations";
          type = (types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecTalosctl"));
        };
      };

      config = {
        "drain" = mkOverride 1002 null;
        "healthChecks" = mkOverride 1002 null;
        "hooks" = mkOverride 1002 null;
        "maintenance" = mkOverride 1002 null;
        "nodeSelector" = mkOverride 1002 null;
        "parallelism" = mkOverride 1002 null;
        "policy" = mkOverride 1002 null;
        "silences" = mkOverride 1002 null;
        "talos" = mkOverride 1002 null;
        "talosctl" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecDrain" = {

      options = {
        "disableEviction" = mkOption {
          description = "DisableEviction forces drain to use delete, even if eviction is supported.";
          type = (types.nullOr types.bool);
        };
        "enabled" = mkOption {
          description = "Enabled drains the node before it is rebooted for upgrade.";
          type = types.bool;
        };
      };

      config = {
        "disableEviction" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHealthChecks" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion of the resource to check";
          type = types.str;
        };
        "description" = mkOption {
          description = "Description of what this check validates (for status/logging)";
          type = (types.nullOr types.str);
        };
        "expr" = mkOption {
          description = "CEL expression that must evaluate to true for the check to pass\nThe resource object is available as 'object' and status as 'status'";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind of the resource to check";
          type = types.str;
        };
        "labelSelector" = mkOption {
          description = "LabelSelector selects resources to check when name is empty";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHealthChecksLabelSelector"
            )
          );
        };
        "name" = mkOption {
          description = "Name of the specific resource (optional, if empty checks all resources of this kind)";
          type = (types.nullOr types.str);
        };
        "namespace" = mkOption {
          description = "Namespace of the resource (optional, for namespaced resources)";
          type = (types.nullOr types.str);
        };
        "timeout" = mkOption {
          description = "Timeout for this health check";
          type = (types.nullOr (types.withMinLength 2 types.str));
        };
      };

      config = {
        "description" = mkOverride 1002 null;
        "labelSelector" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "namespace" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHealthChecksLabelSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHealthChecksLabelSelectorMatchExpressions"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHealthChecksLabelSelectorMatchExpressions" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooks" = {

      options = {
        "post" = mkOption {
          description = "Post runs sequentially after the upgrade reaches a terminal state.\nAlways runs if any pre-hook was attempted; failures don't override the\nupgrade outcome.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPost"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "pre" = mkOption {
          description = "Pre runs sequentially before any node is touched.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPre"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "post" = mkOverride 1002 null;
        "pre" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPost" = {

      options = {
        "activeDeadlineSeconds" = mkOption {
          description = "ActiveDeadlineSeconds for the hook Job. Defaults to 600.";
          type = (types.nullOr (types.withMinimum 1 types.int));
        };
        "args" = mkOption {
          description = "Args are passed to the entrypoint.";
          type = (types.nullOr (types.listOf types.str));
        };
        "backoffLimit" = mkOption {
          description = "BackoffLimit for the hook Job. Defaults to 0 (fail fast, no retries).";
          type = (types.nullOr (types.withMinimum 0 types.int));
        };
        "command" = mkOption {
          description = "Command overrides the image entrypoint.";
          type = (types.nullOr (types.listOf types.str));
        };
        "env" = mkOption {
          description = "Env are environment variables for the hook container.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnv"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "envFrom" = mkOption {
          description = "EnvFrom sources environment variables from ConfigMaps or Secrets.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvFrom")
            )
          );
        };
        "image" = mkOption {
          description = "Image is the container image to run.";
          type = (types.withMinLength 1 types.str);
        };
        "imagePullPolicy" = mkOption {
          description = "ImagePullPolicy for the hook container.";
          type = (
            types.nullOr (
              types.enum [
                "Always"
                "Never"
                "IfNotPresent"
              ]
            )
          );
        };
        "name" = mkOption {
          description = "Name is a human-readable identifier, unique within its pre/post list.";
          type = (types.withMaxLength 63 (types.withMinLength 1 types.str));
        };
        "serviceAccountName" = mkOption {
          description = "ServiceAccountName for the hook pod. Defaults to \"default\".";
          type = (types.nullOr types.str);
        };
        "volumeMounts" = mkOption {
          description = "VolumeMounts are container volume mounts.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumeMounts"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "volumes" = mkOption {
          description = "Volumes are pod-level volumes (typically Secrets / ConfigMaps).";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumes"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "activeDeadlineSeconds" = mkOverride 1002 null;
        "args" = mkOverride 1002 null;
        "backoffLimit" = mkOverride 1002 null;
        "command" = mkOverride 1002 null;
        "env" = mkOverride 1002 null;
        "envFrom" = mkOverride 1002 null;
        "imagePullPolicy" = mkOverride 1002 null;
        "serviceAccountName" = mkOverride 1002 null;
        "volumeMounts" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnv" = {

      options = {
        "name" = mkOption {
          description = "Name of the environment variable.\nMay consist of any printable ASCII characters except '='.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Variable references $(VAR_NAME) are expanded\nusing the previously defined environment variables in the container and\nany service environment variables. If a variable cannot be resolved,\nthe reference in the input string will be unchanged. Double $$ are reduced\nto a single $, which allows for escaping the $(VAR_NAME) syntax: i.e.\n\"$$(VAR_NAME)\" will produce the string literal \"$(VAR_NAME)\".\nEscaped references will never be expanded, regardless of whether the variable\nexists or not.\nDefaults to \"\".";
          type = (types.nullOr types.str);
        };
        "valueFrom" = mkOption {
          description = "Source for the environment variable's value. Cannot be used if value is not empty.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFrom"
            )
          );
        };
      };

      config = {
        "value" = mkOverride 1002 null;
        "valueFrom" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvFrom" = {

      options = {
        "configMapRef" = mkOption {
          description = "The ConfigMap to select from";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvFromConfigMapRef"
            )
          );
        };
        "prefix" = mkOption {
          description = "Optional text to prepend to the name of each environment variable.\nMay consist of any printable ASCII characters except '='.";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "The Secret to select from";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvFromSecretRef"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvFromConfigMapRef" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvFromSecretRef" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFromConfigMapKeyRef"
            )
          );
        };
        "fieldRef" = mkOption {
          description = "Selects a field of the pod: supports metadata.name, metadata.namespace, `metadata.labels['<KEY>']`, `metadata.annotations['<KEY>']`,\nspec.nodeName, spec.serviceAccountName, status.hostIP, status.podIP, status.podIPs.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFromFieldRef"
            )
          );
        };
        "fileKeyRef" = mkOption {
          description = "FileKeyRef selects a key of the env file.\nRequires the EnvFiles feature gate to be enabled.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFromFileKeyRef"
            )
          );
        };
        "resourceFieldRef" = mkOption {
          description = "Selects a resource of the container: only resources limits and requests\n(limits.cpu, limits.memory, limits.ephemeral-storage, requests.cpu, requests.memory and requests.ephemeral-storage) are currently supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFromResourceFieldRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a secret in the pod's namespace";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFromSecretKeyRef"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select from the ConfigMap's Data field.\nKeys in the BinaryData field are not currently propagated to container env vars.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFromFieldRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFromFileKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key within the env file. An invalid key will prevent the pod from starting.\nThe keys defined within a source may consist of any printable ASCII characters except '='.\nDuring Alpha stage of the EnvFiles feature gate, the key size is limited to 128 characters.";
          type = types.str;
        };
        "optional" = mkOption {
          description = "Specify whether the file or its key must be defined. If the file or key\ndoes not exist, then the env var is not published.\nIf optional is set to true and the specified key does not exist,\nthe environment variable will not be set in the Pod's containers.\n\nIf optional is set to false and the specified key does not exist,\nan error will be returned during Pod creation.";
          type = (types.nullOr types.bool);
        };
        "path" = mkOption {
          description = "The path within the volume from which to select the file.\nMust be relative and may not contain the '..' path or start with '..'.";
          type = types.str;
        };
        "volumeName" = mkOption {
          description = "The name of the volume mount containing the env file.";
          type = types.str;
        };
      };

      config = {
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFromResourceFieldRef" = {

      options = {
        "containerName" = mkOption {
          description = "Container name: required for volumes, optional for env vars";
          type = (types.nullOr types.str);
        };
        "divisor" = mkOption {
          description = "Specifies the output format of the exposed resources, defaults to \"1\"";
          type = (types.nullOr (types.either types.int types.str));
        };
        "resource" = mkOption {
          description = "Required: resource to select";
          type = types.str;
        };
      };

      config = {
        "containerName" = mkOverride 1002 null;
        "divisor" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostEnvValueFromSecretKeyRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumeMounts" = {

      options = {
        "bindMountOptions" = mkOption {
          description = "bindMountOptions is the list of additional bind mount options to apply when\nmounting this volume into the container. Allowed values are noexec,\nnodev, and nosuid. These are Linux mount options and have no effect on\nWindows nodes.\nThis field is not supported with image volumes.\nThis is an alpha field and requires enabling the VolumeBindMountOptions feature gate.";
          type = (types.nullOr (types.listOf types.str));
        };
        "mountPath" = mkOption {
          description = "Path within the container at which the volume should be mounted.";
          type = types.str;
        };
        "mountPropagation" = mkOption {
          description = "mountPropagation determines how mounts are propagated from the host\nto container and the other way around.\nWhen not set, MountPropagationNone is used.\nThis field is beta in 1.10.\nWhen RecursiveReadOnly is set to IfPossible or to Enabled, MountPropagation must be None or unspecified\n(which defaults to None).";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "This must match the Name of a Volume.";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "Mounted read-only if true, read-write otherwise (false or unspecified).\nDefaults to false.";
          type = (types.nullOr types.bool);
        };
        "recursiveReadOnly" = mkOption {
          description = "RecursiveReadOnly specifies whether read-only mounts should be handled\nrecursively.\n\nIf ReadOnly is false, this field has no meaning and must be unspecified.\n\nIf ReadOnly is true, and this field is set to Disabled, the mount is not made\nrecursively read-only.  If this field is set to IfPossible, the mount is made\nrecursively read-only, if it is supported by the container runtime.  If this\nfield is set to Enabled, the mount is made recursively read-only if it is\nsupported by the container runtime, otherwise the pod will not be started and\nan error will be generated to indicate the reason.\n\nIf this field is set to IfPossible or Enabled, MountPropagation must be set to\nNone (or be unspecified, which defaults to None).\n\nIf this field is not specified, it is treated as an equivalent of Disabled.";
          type = (types.nullOr types.str);
        };
        "subPath" = mkOption {
          description = "Path within the volume from which the container's volume should be mounted.\nDefaults to \"\" (volume's root).";
          type = (types.nullOr types.str);
        };
        "subPathExpr" = mkOption {
          description = "Expanded path within the volume from which the container's volume should be mounted.\nBehaves similarly to SubPath but environment variable references $(VAR_NAME) are expanded using the container's environment.\nDefaults to \"\" (volume's root).\nSubPathExpr and SubPath are mutually exclusive.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "bindMountOptions" = mkOverride 1002 null;
        "mountPropagation" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "recursiveReadOnly" = mkOverride 1002 null;
        "subPath" = mkOverride 1002 null;
        "subPathExpr" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumes" = {

      options = {
        "awsElasticBlockStore" = mkOption {
          description = "awsElasticBlockStore represents an AWS Disk resource that is attached to a\nkubelet's host machine and then exposed to the pod.\nDeprecated: AWSElasticBlockStore is deprecated. All operations for the in-tree\nawsElasticBlockStore type are redirected to the ebs.csi.aws.com CSI driver.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesAwsElasticBlockStore"
            )
          );
        };
        "azureDisk" = mkOption {
          description = "azureDisk represents an Azure Data Disk mount on the host and bind mount to the pod.\nDeprecated: AzureDisk is deprecated. All operations for the in-tree azureDisk type\nare redirected to the disk.csi.azure.com CSI driver.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesAzureDisk"
            )
          );
        };
        "azureFile" = mkOption {
          description = "azureFile represents an Azure File Service mount on the host and bind mount to the pod.\nDeprecated: AzureFile is deprecated. All operations for the in-tree azureFile type\nare redirected to the file.csi.azure.com CSI driver.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesAzureFile"
            )
          );
        };
        "cephfs" = mkOption {
          description = "cephFS represents a Ceph FS mount on the host that shares a pod's lifetime.\nDeprecated: CephFS is deprecated and the in-tree cephfs type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCephfs"
            )
          );
        };
        "cinder" = mkOption {
          description = "cinder represents a cinder volume attached and mounted on kubelets host machine.\nDeprecated: Cinder is deprecated. All operations for the in-tree cinder type\nare redirected to the cinder.csi.openstack.org CSI driver.\nMore info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCinder"
            )
          );
        };
        "configMap" = mkOption {
          description = "configMap represents a configMap that should populate this volume";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesConfigMap"
            )
          );
        };
        "csi" = mkOption {
          description = "csi (Container Storage Interface) represents ephemeral storage that is handled by certain external CSI drivers.";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCsi")
          );
        };
        "downwardAPI" = mkOption {
          description = "downwardAPI represents downward API about the pod that should populate this volume";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesDownwardAPI"
            )
          );
        };
        "emptyDir" = mkOption {
          description = "emptyDir represents a temporary directory that shares a pod's lifetime.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEmptyDir"
            )
          );
        };
        "ephemeral" = mkOption {
          description = "ephemeral represents a volume that is handled by a cluster storage driver.\nThe volume's lifecycle is tied to the pod that defines it - it will be created before the pod starts,\nand deleted when the pod is removed.\n\nUse this if:\na) the volume is only needed while the pod runs,\nb) features of normal volumes like restoring from snapshot or capacity\n   tracking are needed,\nc) the storage driver is specified through a storage class, and\nd) the storage driver supports dynamic volume provisioning through\n   a PersistentVolumeClaim (see EphemeralVolumeSource for more\n   information on the connection between this volume type\n   and PersistentVolumeClaim).\n\nUse PersistentVolumeClaim or one of the vendor-specific\nAPIs for volumes that persist for longer than the lifecycle\nof an individual pod.\n\nUse CSI for light-weight local ephemeral volumes if the CSI driver is meant to\nbe used that way - see the documentation of the driver for\nmore information.\n\nA pod can use both types of ephemeral volumes and\npersistent volumes at the same time.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeral"
            )
          );
        };
        "fc" = mkOption {
          description = "fc represents a Fibre Channel resource that is attached to a kubelet's host machine and then exposed to the pod.";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesFc")
          );
        };
        "flexVolume" = mkOption {
          description = "flexVolume represents a generic volume resource that is\nprovisioned/attached using an exec based plugin.\nDeprecated: FlexVolume is deprecated. Consider using a CSIDriver instead.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesFlexVolume"
            )
          );
        };
        "flocker" = mkOption {
          description = "flocker represents a Flocker volume attached to a kubelet's host machine. This depends on the Flocker control service being running.\nDeprecated: Flocker is deprecated and the in-tree flocker type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesFlocker"
            )
          );
        };
        "gcePersistentDisk" = mkOption {
          description = "gcePersistentDisk represents a GCE Disk resource that is attached to a\nkubelet's host machine and then exposed to the pod.\nDeprecated: GCEPersistentDisk is deprecated. All operations for the in-tree\ngcePersistentDisk type are redirected to the pd.csi.storage.gke.io CSI driver.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesGcePersistentDisk"
            )
          );
        };
        "gitRepo" = mkOption {
          description = "gitRepo represents a git repository at a particular revision.\nDeprecated: GitRepo is deprecated. To provision a container with a git repo, mount an\nEmptyDir into an InitContainer that clones the repo using git, then mount the EmptyDir\ninto the Pod's container.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesGitRepo"
            )
          );
        };
        "glusterfs" = mkOption {
          description = "glusterfs represents a Glusterfs mount on the host that shares a pod's lifetime.\nDeprecated: Glusterfs is deprecated and the in-tree glusterfs type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesGlusterfs"
            )
          );
        };
        "hostPath" = mkOption {
          description = "hostPath represents a pre-existing file or directory on the host\nmachine that is directly exposed to the container. This is generally\nused for system agents or other privileged things that are allowed\nto see the host machine. Most containers will NOT need this.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesHostPath"
            )
          );
        };
        "image" = mkOption {
          description = "image represents an OCI object (a container image or artifact) pulled and mounted on the kubelet's host machine.\nThe volume is resolved at pod startup depending on which PullPolicy value is provided:\n\n- Always: the kubelet always attempts to pull the reference. Container creation will fail If the pull fails.\n- Never: the kubelet never pulls the reference and only uses a local image or artifact. Container creation will fail if the reference isn't present.\n- IfNotPresent: the kubelet pulls if the reference isn't already present on disk. Container creation will fail if the reference isn't present and the pull fails.\n\nThe volume gets re-resolved if the pod gets deleted and recreated, which means that new remote content will become available on pod recreation.\nA failure to resolve or pull the image during pod startup will block containers from starting and may add significant latency. Failures will be retried using normal volume backoff and will be reported on the pod reason and message.\nThe types of objects that may be mounted by this volume are defined by the container runtime implementation on a host machine and at minimum must include all valid types supported by the container image field.\nThe OCI object gets mounted in a single directory (spec.containers[*].volumeMounts.mountPath) by merging the manifest layers in the same way as for container images.\nThe volume will be mounted read-only (ro).\nSub path mounts for containers are not supported (spec.containers[*].volumeMounts.subpath) before 1.33.\nThe field spec.securityContext.fsGroupChangePolicy has no effect on this volume type.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesImage"
            )
          );
        };
        "iscsi" = mkOption {
          description = "iscsi represents an ISCSI Disk resource that is attached to a\nkubelet's host machine and then exposed to the pod.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes/#iscsi";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesIscsi"
            )
          );
        };
        "name" = mkOption {
          description = "name of the volume.\nMust be a DNS_LABEL and unique within the pod.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host that shares a pod's lifetime\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesNfs")
          );
        };
        "persistentVolumeClaim" = mkOption {
          description = "persistentVolumeClaimVolumeSource represents a reference to a\nPersistentVolumeClaim in the same namespace.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesPersistentVolumeClaim"
            )
          );
        };
        "photonPersistentDisk" = mkOption {
          description = "photonPersistentDisk represents a PhotonController persistent disk attached and mounted on kubelets host machine.\nDeprecated: PhotonPersistentDisk is deprecated and the in-tree photonPersistentDisk type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesPhotonPersistentDisk"
            )
          );
        };
        "portworxVolume" = mkOption {
          description = "portworxVolume represents a portworx volume attached and mounted on kubelets host machine.\nDeprecated: PortworxVolume is deprecated. All operations for the in-tree portworxVolume type\nare redirected to the pxd.portworx.com CSI driver.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesPortworxVolume"
            )
          );
        };
        "projected" = mkOption {
          description = "projected items for all in one resources secrets, configmaps, and downward API";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjected"
            )
          );
        };
        "quobyte" = mkOption {
          description = "quobyte represents a Quobyte mount on the host that shares a pod's lifetime.\nDeprecated: Quobyte is deprecated and the in-tree quobyte type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesQuobyte"
            )
          );
        };
        "rbd" = mkOption {
          description = "rbd represents a Rados Block Device mount on the host that shares a pod's lifetime.\nDeprecated: RBD is deprecated and the in-tree rbd type is no longer supported.";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesRbd")
          );
        };
        "scaleIO" = mkOption {
          description = "scaleIO represents a ScaleIO persistent volume attached and mounted on Kubernetes nodes.\nDeprecated: ScaleIO is deprecated and the in-tree scaleIO type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesScaleIO"
            )
          );
        };
        "secret" = mkOption {
          description = "secret represents a secret that should populate this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesSecret"
            )
          );
        };
        "storageos" = mkOption {
          description = "storageOS represents a StorageOS volume attached and mounted on Kubernetes nodes.\nDeprecated: StorageOS is deprecated and the in-tree storageos type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesStorageos"
            )
          );
        };
        "vsphereVolume" = mkOption {
          description = "vsphereVolume represents a vSphere volume attached and mounted on kubelets host machine.\nDeprecated: VsphereVolume is deprecated. All operations for the in-tree vsphereVolume type\nare redirected to the csi.vsphere.vmware.com CSI driver.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesVsphereVolume"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesAwsElasticBlockStore" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount.\nTip: Ensure that the filesystem type is supported by the host operating system.\nExamples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = (types.nullOr types.str);
        };
        "partition" = mkOption {
          description = "partition is the partition in the volume that you want to mount.\nIf omitted, the default is to mount by volume name.\nExamples: For volume /dev/sda1, you specify the partition as \"1\".\nSimilarly, the volume partition for /dev/sda is \"0\" (or you can leave the property empty).";
          type = (types.nullOr types.int);
        };
        "readOnly" = mkOption {
          description = "readOnly value true will force the readOnly setting in VolumeMounts.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = (types.nullOr types.bool);
        };
        "volumeID" = mkOption {
          description = "volumeID is unique ID of the persistent disk resource in AWS (Amazon EBS volume).\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "partition" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesAzureDisk" = {

      options = {
        "cachingMode" = mkOption {
          description = "cachingMode is the Host Caching mode: None, Read Only, Read Write.";
          type = (types.nullOr types.str);
        };
        "diskName" = mkOption {
          description = "diskName is the Name of the data disk in the blob storage";
          type = types.str;
        };
        "diskURI" = mkOption {
          description = "diskURI is the URI of data disk in the blob storage";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType is Filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "kind expected values are Shared: multiple blob disks per storage account  Dedicated: single blob disk per storage account  Managed: azure managed data disk (only in managed availability set). defaults to shared";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly Defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesAzureFile" = {

      options = {
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretName" = mkOption {
          description = "secretName is the  name of secret that contains Azure Storage Account Name and Key";
          type = types.str;
        };
        "shareName" = mkOption {
          description = "shareName is the azure share Name";
          type = types.str;
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCephfs" = {

      options = {
        "monitors" = mkOption {
          description = "monitors is Required: Monitors is a collection of Ceph monitors\nMore info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.listOf types.str);
        };
        "path" = mkOption {
          description = "path is Optional: Used as the mounted root, rather than the full Ceph tree, default is /";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: Defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.\nMore info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr types.bool);
        };
        "secretFile" = mkOption {
          description = "secretFile is Optional: SecretFile is the path to key ring for User, default is /etc/ceph/user.secret\nMore info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "secretRef is Optional: SecretRef is reference to the authentication secret for User, default is empty.\nMore info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCephfsSecretRef"
            )
          );
        };
        "user" = mkOption {
          description = "user is optional: User is the rados user name, default is admin\nMore info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCephfsSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCinder" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nExamples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.\nMore info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.\nMore info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is optional: points to a secret object containing parameters used to connect\nto OpenStack.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCinderSecretRef"
            )
          );
        };
        "volumeID" = mkOption {
          description = "volumeID used to identify the volume in cinder.\nMore info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCinderSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesConfigMap" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nDefaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "defaultUser" = mkOption {
          description = "defaultUser is Optional: The owner UID of the created files by default.\nThe defaultUser field is only used as a fallback when the item-level user field is unset.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items if unspecified, each key-value pair in the Data field of the referenced\nConfigMap will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the ConfigMap,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesConfigMapItems"
              )
            )
          );
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "optional specify whether the ConfigMap or its keys must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "defaultUser" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesConfigMapItems" = {

      options = {
        "key" = mkOption {
          description = "key is the key to project.";
          type = types.str;
        };
        "mode" = mkOption {
          description = "mode is Optional: mode bits used to set permissions on this file.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "path is the relative path of the file to map the key to.\nMay not be an absolute path.\nMay not contain the path element '..'.\nMay not start with the string '..'.";
          type = types.str;
        };
        "user" = mkOption {
          description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "mode" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCsi" = {

      options = {
        "driver" = mkOption {
          description = "driver is the name of the CSI driver that handles this volume.\nConsult with your admin for the correct name as registered in the cluster.";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType to mount. Ex. \"ext4\", \"xfs\", \"ntfs\".\nIf not provided, the empty value is passed to the associated CSI driver\nwhich will determine the default filesystem to apply.";
          type = (types.nullOr types.str);
        };
        "nodePublishSecretRef" = mkOption {
          description = "nodePublishSecretRef is a reference to the secret object containing\nsensitive information to pass to the CSI driver to complete the CSI\nNodePublishVolume and NodeUnpublishVolume calls.\nThis field is optional, and  may be empty if no secret is required. If the\nsecret object contains more than one secret, all secret references are passed.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCsiNodePublishSecretRef"
            )
          );
        };
        "readOnly" = mkOption {
          description = "readOnly specifies a read-only configuration for the volume.\nDefaults to false (read/write).";
          type = (types.nullOr types.bool);
        };
        "volumeAttributes" = mkOption {
          description = "volumeAttributes stores driver-specific properties that are passed to the CSI\ndriver. Consult your driver's documentation for supported values.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesCsiNodePublishSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesDownwardAPI" = {

      options = {
        "defaultMode" = mkOption {
          description = "Optional: mode bits to use on created files by default. Must be a\nOptional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nDefaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "defaultUser" = mkOption {
          description = "defaultUser is Optional: The owner UID of the created files by default.\nThe defaultUser field is only used as a fallback when the item-level user field is unset.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "Items is a list of downward API volume file";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesDownwardAPIItems"
              )
            )
          );
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "defaultUser" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesDownwardAPIItems" = {

      options = {
        "fieldRef" = mkOption {
          description = "Required: Selects a field of the pod: only annotations, labels, name, namespace and uid are supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesDownwardAPIItemsFieldRef"
            )
          );
        };
        "mode" = mkOption {
          description = "Optional: mode bits used to set permissions on this file, must be an octal value\nbetween 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "Required: Path is  the relative path name of the file to be created. Must not be absolute or contain the '..' path. Must be utf-8 encoded. The first item of the relative path must not start with '..'";
          type = types.str;
        };
        "resourceFieldRef" = mkOption {
          description = "Selects a resource of the container: only resources limits and requests\n(limits.cpu, limits.memory, requests.cpu and requests.memory) are currently supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesDownwardAPIItemsResourceFieldRef"
            )
          );
        };
        "user" = mkOption {
          description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "fieldRef" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "resourceFieldRef" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesDownwardAPIItemsFieldRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesDownwardAPIItemsResourceFieldRef" =
      {

        options = {
          "containerName" = mkOption {
            description = "Container name: required for volumes, optional for env vars";
            type = (types.nullOr types.str);
          };
          "divisor" = mkOption {
            description = "Specifies the output format of the exposed resources, defaults to \"1\"";
            type = (types.nullOr (types.either types.int types.str));
          };
          "resource" = mkOption {
            description = "Required: resource to select";
            type = types.str;
          };
        };

        config = {
          "containerName" = mkOverride 1002 null;
          "divisor" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEmptyDir" = {

      options = {
        "medium" = mkOption {
          description = "medium represents what type of storage medium should back this directory.\nThe default is \"\" which means to use the node's default medium.\nMust be an empty string (default) or Memory.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir";
          type = (types.nullOr types.str);
        };
        "mode" = mkOption {
          description = "mode specifies the permission bits for the emptyDir directory, in numeric\nnotation (e.g., 0755, 01777). Must be a value between 0000 and 01777.\nIf not specified, defaults to 0777.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup. If fsGroup is specified, the fsGroup permissions\nwill override the mode specified here.\nThis field has no effect on Windows.\nThis field is alpha and requires EmptyDirVolumeMode featuregate to be enabled.";
          type = (types.nullOr types.int);
        };
        "sizeLimit" = mkOption {
          description = "sizeLimit is the total amount of local storage required for this EmptyDir volume.\nThe size limit is also applicable for memory medium.\nThe maximum usage on memory medium EmptyDir would be the minimum value between\nthe SizeLimit specified here and the sum of memory limits of all containers in a pod.\nThe default is nil which means that the limit is undefined.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir";
          type = (types.nullOr (types.either types.int types.str));
        };
      };

      config = {
        "medium" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "sizeLimit" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeral" = {

      options = {
        "volumeClaimTemplate" = mkOption {
          description = "Will be used to create a stand-alone PVC to provision the volume.\nThe pod in which this EphemeralVolumeSource is embedded will be the\nowner of the PVC, i.e. the PVC will be deleted together with the\npod.  The name of the PVC will be `<pod name>-<volume name>` where\n`<volume name>` is the name from the `PodSpec.Volumes` array\nentry. Pod validation will reject the pod if the concatenated name\nis not valid for a PVC (for example, too long).\n\nAn existing PVC with that name that is not owned by the pod\nwill *not* be used for the pod to avoid using an unrelated\nvolume by mistake. Starting the pod is then blocked until\nthe unrelated PVC is removed. If such a pre-created PVC is\nmeant to be used by the pod, the PVC has to updated with an\nowner reference to the pod once the pod exists. Normally\nthis should not be necessary, but it may be useful when\nmanually reconstructing a broken cluster.\n\nThis field is read-only and no changes will be made by Kubernetes\nto the PVC after it has been created.\n\nRequired, must not be nil.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplate"
            )
          );
        };
      };

      config = {
        "volumeClaimTemplate" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplate" =
      {

        options = {
          "metadata" = mkOption {
            description = "May contain labels and annotations that will be copied into the PVC\nwhen creating it. No other fields are allowed and will be rejected during\nvalidation.";
            type = (types.nullOr types.attrs);
          };
          "spec" = mkOption {
            description = "The specification for the PersistentVolumeClaim. The entire content is\ncopied unchanged into the PVC that gets created from this\ntemplate. The same fields as in a PersistentVolumeClaim\nare also valid here.";
            type = (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpec"
            );
          };
        };

        config = {
          "metadata" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpec" =
      {

        options = {
          "accessModes" = mkOption {
            description = "accessModes contains the desired access modes the volume should have.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes-1";
            type = (types.nullOr (types.listOf types.str));
          };
          "dataSource" = mkOption {
            description = "dataSource field can be used to specify either:\n* An existing VolumeSnapshot object (snapshot.storage.k8s.io/VolumeSnapshot)\n* An existing PVC (PersistentVolumeClaim)\nIf the provisioner or an external controller can support the specified data source,\nit will create a new volume based on the contents of the specified data source.\ndataSource contents will be copied to dataSourceRef, and dataSourceRef contents will be\ncopied to dataSource when dataSourceRef.namespace is not specified.\nIf the namespace is specified, then dataSourceRef will not be copied to dataSource.";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpecDataSource"
              )
            );
          };
          "dataSourceRef" = mkOption {
            description = "dataSourceRef specifies the object from which to populate the volume with data, if a non-empty\nvolume is desired. This may be any object from a non-empty API group (non\ncore object) or a PersistentVolumeClaim object.\nWhen this field is specified, volume binding will only succeed if the type of\nthe specified object matches some installed volume populator or dynamic\nprovisioner.\nThis field will replace the functionality of the dataSource field and as such\nif both fields are non-empty, they must have the same value. For backwards\ncompatibility, when namespace isn't specified in dataSourceRef,\nboth fields (dataSource and dataSourceRef) will be set to the same\nvalue automatically if one of them is empty and the other is non-empty.\nWhen namespace is specified in dataSourceRef,\ndataSource isn't set to the same value and must be empty.\nThere are three important differences between dataSource and dataSourceRef:\n* While dataSource only allows two specific types of objects, dataSourceRef\n  allows any non-core object, as well as PersistentVolumeClaim objects.\n* While dataSource ignores disallowed values (dropping them), dataSourceRef\n  preserves all values, and generates an error if a disallowed value is\n  specified.\n* While dataSource only allows local objects, dataSourceRef allows objects\n  in any namespaces.\n(Alpha) Using the namespace field of dataSourceRef requires the CrossNamespaceVolumeDataSource feature gate to be enabled.";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpecDataSourceRef"
              )
            );
          };
          "resources" = mkOption {
            description = "resources represents the minimum resources the volume should have.\nUsers are allowed to specify resource requirements\nthat are lower than previous value but must still be higher than capacity recorded in the\nstatus field of the claim.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#resources";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpecResources"
              )
            );
          };
          "selector" = mkOption {
            description = "selector is a label query over volumes to consider for binding.";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpecSelector"
              )
            );
          };
          "storageClassName" = mkOption {
            description = "storageClassName is the name of the StorageClass required by the claim.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#class-1";
            type = (types.nullOr types.str);
          };
          "volumeAttributesClassName" = mkOption {
            description = "volumeAttributesClassName may be used to set the VolumeAttributesClass used by this claim.\nIf specified, the CSI driver will create or update the volume with the attributes defined\nin the corresponding VolumeAttributesClass. This has a different purpose than storageClassName,\nit can be changed after the claim is created. An empty string or nil value indicates that no\nVolumeAttributesClass will be applied to the claim. If the claim enters an Infeasible error state,\nthis field can be reset to its previous value (including nil) to cancel the modification.\nIf the resource referred to by volumeAttributesClass does not exist, this PersistentVolumeClaim will be\nset to a Pending state, as reflected by the modifyVolumeStatus field, until such as a resource\nexists.\nMore info: https://kubernetes.io/docs/concepts/storage/volume-attributes-classes/";
            type = (types.nullOr types.str);
          };
          "volumeMode" = mkOption {
            description = "volumeMode defines what type of volume is required by the claim.\nValue of Filesystem is implied when not included in claim spec.";
            type = (types.nullOr types.str);
          };
          "volumeName" = mkOption {
            description = "volumeName is the binding reference to the PersistentVolume backing this claim.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpecDataSource" =
      {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpecDataSourceRef" =
      {

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
          "namespace" = mkOption {
            description = "Namespace is the namespace of resource being referenced\nNote that when a namespace is specified, a gateway.networking.k8s.io/ReferenceGrant object is required in the referent namespace to allow that namespace's owner to accept the reference. See the ReferenceGrant documentation for details.\n(Alpha) This field requires the CrossNamespaceVolumeDataSource feature gate to be enabled.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "apiGroup" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpecResources" =
      {

        options = {
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
          "limits" = mkOverride 1002 null;
          "requests" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpecSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpecSelectorMatchExpressions"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesEphemeralVolumeClaimTemplateSpecSelectorMatchExpressions" =
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesFc" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "lun" = mkOption {
          description = "lun is Optional: FC target lun number";
          type = (types.nullOr types.int);
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: Defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "targetWWNs" = mkOption {
          description = "targetWWNs is Optional: FC target worldwide names (WWNs)";
          type = (types.nullOr (types.listOf types.str));
        };
        "wwids" = mkOption {
          description = "wwids Optional: FC volume world wide identifiers (wwids)\nEither wwids or combination of targetWWNs and lun must be set, but not both simultaneously.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesFlexVolume" = {

      options = {
        "driver" = mkOption {
          description = "driver is the name of the driver to use for this volume.";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". The default filesystem depends on FlexVolume script.";
          type = (types.nullOr types.str);
        };
        "options" = mkOption {
          description = "options is Optional: this field holds extra command options if any.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is Optional: secretRef is reference to the secret object containing\nsensitive information to pass to the plugin scripts. This may be\nempty if no secret object is specified. If the secret object\ncontains more than one secret, all secrets are passed to the plugin\nscripts.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesFlexVolumeSecretRef"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesFlexVolumeSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesFlocker" = {

      options = {
        "datasetName" = mkOption {
          description = "datasetName is Name of the dataset stored as metadata -> name on the dataset for Flocker\nshould be considered as deprecated";
          type = (types.nullOr types.str);
        };
        "datasetUUID" = mkOption {
          description = "datasetUUID is the UUID of the dataset. This is unique identifier of a Flocker dataset";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "datasetName" = mkOverride 1002 null;
        "datasetUUID" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesGcePersistentDisk" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is filesystem type of the volume that you want to mount.\nTip: Ensure that the filesystem type is supported by the host operating system.\nExamples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr types.str);
        };
        "partition" = mkOption {
          description = "partition is the partition in the volume that you want to mount.\nIf omitted, the default is to mount by volume name.\nExamples: For volume /dev/sda1, you specify the partition as \"1\".\nSimilarly, the volume partition for /dev/sda is \"0\" (or you can leave the property empty).\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr types.int);
        };
        "pdName" = mkOption {
          description = "pdName is unique name of the PD resource in GCE. Used to identify the disk in GCE.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts.\nDefaults to false.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "partition" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesGitRepo" = {

      options = {
        "directory" = mkOption {
          description = "directory is the target directory name.\nMust not contain or start with '..'.  If '.' is supplied, the volume directory will be the\ngit repository.  Otherwise, if specified, the volume will contain the git repository in\nthe subdirectory with the given name.";
          type = (types.nullOr types.str);
        };
        "repository" = mkOption {
          description = "repository is the URL";
          type = types.str;
        };
        "revision" = mkOption {
          description = "revision is the commit hash for the specified revision.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "directory" = mkOverride 1002 null;
        "revision" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesGlusterfs" = {

      options = {
        "endpoints" = mkOption {
          description = "endpoints is the endpoint name that details Glusterfs topology.";
          type = types.str;
        };
        "path" = mkOption {
          description = "path is the Glusterfs volume path.\nMore info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the Glusterfs volume to be mounted with read-only permissions.\nDefaults to false.\nMore info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesHostPath" = {

      options = {
        "path" = mkOption {
          description = "path of the directory on the host.\nIf the path is a symlink, it will follow the link to the real path.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath";
          type = types.str;
        };
        "type" = mkOption {
          description = "type for HostPath Volume\nDefaults to \"\"\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesImage" = {

      options = {
        "pullPolicy" = mkOption {
          description = "Policy for pulling OCI objects. Possible values are:\nAlways: the kubelet always attempts to pull the reference. Container creation will fail If the pull fails.\nNever: the kubelet never pulls the reference and only uses a local image or artifact. Container creation will fail if the reference isn't present.\nIfNotPresent: the kubelet pulls if the reference isn't already present on disk. Container creation will fail if the reference isn't present and the pull fails.\nDefaults to Always if :latest tag is specified, or IfNotPresent otherwise.";
          type = (types.nullOr types.str);
        };
        "reference" = mkOption {
          description = "Required: Image or artifact reference to be used.\nBehaves in the same way as pod.spec.containers[*].image.\nPull secrets will be assembled in the same way as for the container image by looking up node credentials, SA image pull secrets, and pod spec image pull secrets.\nMore info: https://kubernetes.io/docs/concepts/containers/images\nThis field is optional to allow higher level config management to default or override\ncontainer images in workload controllers like Deployments and StatefulSets.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "pullPolicy" = mkOverride 1002 null;
        "reference" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesIscsi" = {

      options = {
        "chapAuthDiscovery" = mkOption {
          description = "chapAuthDiscovery defines whether support iSCSI Discovery CHAP authentication";
          type = (types.nullOr types.bool);
        };
        "chapAuthSession" = mkOption {
          description = "chapAuthSession defines whether support iSCSI Session CHAP authentication";
          type = (types.nullOr types.bool);
        };
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount.\nTip: Ensure that the filesystem type is supported by the host operating system.\nExamples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#iscsi";
          type = (types.nullOr types.str);
        };
        "initiatorName" = mkOption {
          description = "initiatorName is the custom iSCSI Initiator Name.\nIf initiatorName is specified with iscsiInterface simultaneously, new iSCSI interface\n<target portal>:<volume name> will be created for the connection.";
          type = (types.nullOr types.str);
        };
        "iqn" = mkOption {
          description = "iqn is the target iSCSI Qualified Name.";
          type = types.str;
        };
        "iscsiInterface" = mkOption {
          description = "iscsiInterface is the interface Name that uses an iSCSI transport.\nDefaults to 'default' (tcp).";
          type = (types.nullOr types.str);
        };
        "lun" = mkOption {
          description = "lun represents iSCSI Target Lun number.";
          type = types.int;
        };
        "portals" = mkOption {
          description = "portals is the iSCSI Target Portal List. The portal is either an IP or ip_addr:port if the port\nis other than default (typically TCP ports 860 and 3260).";
          type = (types.nullOr (types.listOf types.str));
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts.\nDefaults to false.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is the CHAP Secret for iSCSI target and initiator authentication";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesIscsiSecretRef"
            )
          );
        };
        "targetPortal" = mkOption {
          description = "targetPortal is iSCSI Target Portal. The Portal is either an IP or ip_addr:port if the port\nis other than default (typically TCP ports 860 and 3260).";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesIscsiSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesNfs" = {

      options = {
        "path" = mkOption {
          description = "path that is exported by the NFS server.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the NFS export to be mounted with read-only permissions.\nDefaults to false.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (types.nullOr types.bool);
        };
        "server" = mkOption {
          description = "server is the hostname or IP address of the NFS server.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = types.str;
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesPersistentVolumeClaim" = {

      options = {
        "claimName" = mkOption {
          description = "claimName is the name of a PersistentVolumeClaim in the same namespace as the pod using this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly Will force the ReadOnly setting in VolumeMounts.\nDefault false.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesPhotonPersistentDisk" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "pdID" = mkOption {
          description = "pdID is the ID that identifies Photon Controller persistent disk";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesPortworxVolume" = {

      options = {
        "fsType" = mkOption {
          description = "fSType represents the filesystem type to mount\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "volumeID" = mkOption {
          description = "volumeID uniquely identifies a Portworx volume";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjected" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode are the mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "defaultUser" = mkOption {
          description = "defaultUser is Optional: The owner UID of the created files by default.\nThe defaultUser field is only used as a fallback when the item-level user field is unset.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
        "sources" = mkOption {
          description = "sources is the list of volume projections. Each entry in this list\nhandles one source.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSources"
              )
            )
          );
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "defaultUser" = mkOverride 1002 null;
        "sources" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSources" = {

      options = {
        "clusterTrustBundle" = mkOption {
          description = "ClusterTrustBundle allows a pod to access the `.spec.trustBundle` field\nof ClusterTrustBundle objects in an auto-updating file.\n\nAlpha, gated by the ClusterTrustBundleProjection feature gate.\n\nClusterTrustBundle objects can either be selected by name, or by the\ncombination of signer name and a label selector.\n\nKubelet performs aggressive normalization of the PEM contents written\ninto the pod filesystem.  Esoteric PEM features such as inter-block\ncomments and block headers are stripped.  Certificates are deduplicated.\nThe ordering of certificates within the file is arbitrary, and Kubelet\nmay change the order over time.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesClusterTrustBundle"
            )
          );
        };
        "configMap" = mkOption {
          description = "configMap information about the configMap data to project";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesConfigMap"
            )
          );
        };
        "downwardAPI" = mkOption {
          description = "downwardAPI information about the downwardAPI data to project";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesDownwardAPI"
            )
          );
        };
        "podCertificate" = mkOption {
          description = "Projects an auto-rotating credential bundle (private key and certificate\nchain) that the pod can use either as a TLS client or server.\n\nKubelet generates a private key and uses it to send a\nPodCertificateRequest to the named signer.  Once the signer approves the\nrequest and issues a certificate chain, Kubelet writes the key and\ncertificate chain to the pod filesystem.  The pod does not start until\ncertificates have been issued for each podCertificate projected volume\nsource in its spec.\n\nKubelet will begin trying to rotate the certificate at the time indicated\nby the signer using the PodCertificateRequest.Status.BeginRefreshAt\ntimestamp.\n\nKubelet can write a single file, indicated by the credentialBundlePath\nfield, or separate files, indicated by the keyPath and\ncertificateChainPath fields.\n\nThe credential bundle is a single file in PEM format.  The first PEM\nentry is the private key (in PKCS#8 format), and the remaining PEM\nentries are the certificate chain issued by the signer (typically,\nsigners will return their certificate chain in leaf-to-root order).\n\nPrefer using the credential bundle format, since your application code\ncan read it atomically.  If you use keyPath and certificateChainPath,\nyour application must make two separate file reads. If these coincide\nwith a certificate rotation, it is possible that the private key and leaf\ncertificate you read may not correspond to each other.  Your application\nwill need to check for this condition, and re-read until they are\nconsistent.\n\nThe named signer controls chooses the format of the certificate it\nissues; consult the signer implementation's documentation to learn how to\nuse the certificates it issues.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesPodCertificate"
            )
          );
        };
        "secret" = mkOption {
          description = "secret information about the secret data to project";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesSecret"
            )
          );
        };
        "serviceAccountToken" = mkOption {
          description = "serviceAccountToken is information about the serviceAccountToken data to project";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesServiceAccountToken"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesClusterTrustBundle" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "Select all ClusterTrustBundles that match this label selector.  Only has\neffect if signerName is set.  Mutually-exclusive with name.  If unset,\ninterpreted as \"match nothing\".  If set but empty, interpreted as \"match\neverything\".";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesClusterTrustBundleLabelSelector"
              )
            );
          };
          "name" = mkOption {
            description = "Select a single ClusterTrustBundle by object name.  Mutually-exclusive\nwith signerName and labelSelector.";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "If true, don't block pod startup if the referenced ClusterTrustBundle(s)\naren't available.  If using name, then the named ClusterTrustBundle is\nallowed not to exist.  If using signerName, then the combination of\nsignerName and labelSelector is allowed to match zero\nClusterTrustBundles.";
            type = (types.nullOr types.bool);
          };
          "path" = mkOption {
            description = "Relative path from the volume root to write the bundle.";
            type = types.str;
          };
          "signerName" = mkOption {
            description = "Select all ClusterTrustBundles that match this signer name.\nMutually-exclusive with name.  The contents of all selected\nClusterTrustBundles will be unified and deduplicated.";
            type = (types.nullOr types.str);
          };
          "user" = mkOption {
            description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
          "signerName" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesClusterTrustBundleLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesClusterTrustBundleLabelSelectorMatchExpressions"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesClusterTrustBundleLabelSelectorMatchExpressions" =
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesConfigMap" = {

      options = {
        "items" = mkOption {
          description = "items if unspecified, each key-value pair in the Data field of the referenced\nConfigMap will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the ConfigMap,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesConfigMapItems"
              )
            )
          );
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "optional specify whether the ConfigMap or its keys must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "items" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesConfigMapItems" =
      {

        options = {
          "key" = mkOption {
            description = "key is the key to project.";
            type = types.str;
          };
          "mode" = mkOption {
            description = "mode is Optional: mode bits used to set permissions on this file.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
            type = (types.nullOr types.int);
          };
          "path" = mkOption {
            description = "path is the relative path of the file to map the key to.\nMay not be an absolute path.\nMay not contain the path element '..'.\nMay not start with the string '..'.";
            type = types.str;
          };
          "user" = mkOption {
            description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "mode" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesDownwardAPI" = {

      options = {
        "items" = mkOption {
          description = "Items is a list of DownwardAPIVolume file";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesDownwardAPIItems"
              )
            )
          );
        };
      };

      config = {
        "items" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesDownwardAPIItems" =
      {

        options = {
          "fieldRef" = mkOption {
            description = "Required: Selects a field of the pod: only annotations, labels, name, namespace and uid are supported.";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesDownwardAPIItemsFieldRef"
              )
            );
          };
          "mode" = mkOption {
            description = "Optional: mode bits used to set permissions on this file, must be an octal value\nbetween 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
            type = (types.nullOr types.int);
          };
          "path" = mkOption {
            description = "Required: Path is  the relative path name of the file to be created. Must not be absolute or contain the '..' path. Must be utf-8 encoded. The first item of the relative path must not start with '..'";
            type = types.str;
          };
          "resourceFieldRef" = mkOption {
            description = "Selects a resource of the container: only resources limits and requests\n(limits.cpu, limits.memory, requests.cpu and requests.memory) are currently supported.";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesDownwardAPIItemsResourceFieldRef"
              )
            );
          };
          "user" = mkOption {
            description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "fieldRef" = mkOverride 1002 null;
          "mode" = mkOverride 1002 null;
          "resourceFieldRef" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesDownwardAPIItemsFieldRef" =
      {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesDownwardAPIItemsResourceFieldRef" =
      {

        options = {
          "containerName" = mkOption {
            description = "Container name: required for volumes, optional for env vars";
            type = (types.nullOr types.str);
          };
          "divisor" = mkOption {
            description = "Specifies the output format of the exposed resources, defaults to \"1\"";
            type = (types.nullOr (types.either types.int types.str));
          };
          "resource" = mkOption {
            description = "Required: resource to select";
            type = types.str;
          };
        };

        config = {
          "containerName" = mkOverride 1002 null;
          "divisor" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesPodCertificate" =
      {

        options = {
          "certificateChainPath" = mkOption {
            description = "Write the certificate chain at this path in the projected volume.\n\nMost applications should use credentialBundlePath.  When using keyPath\nand certificateChainPath, your application needs to check that the key\nand leaf certificate are consistent, because it is possible to read the\nfiles mid-rotation.";
            type = (types.nullOr types.str);
          };
          "credentialBundlePath" = mkOption {
            description = "Write the credential bundle at this path in the projected volume.\n\nThe credential bundle is a single file that contains multiple PEM blocks.\nThe first PEM block is a PRIVATE KEY block, containing a PKCS#8 private\nkey.\n\nThe remaining blocks are CERTIFICATE blocks, containing the issued\ncertificate chain from the signer (leaf and any intermediates).\n\nUsing credentialBundlePath lets your Pod's application code make a single\natomic read that retrieves a consistent key and certificate chain.  If you\nproject them to separate files, your application code will need to\nadditionally check that the leaf certificate was issued to the key.";
            type = (types.nullOr types.str);
          };
          "keyPath" = mkOption {
            description = "Write the key at this path in the projected volume.\n\nMost applications should use credentialBundlePath.  When using keyPath\nand certificateChainPath, your application needs to check that the key\nand leaf certificate are consistent, because it is possible to read the\nfiles mid-rotation.";
            type = (types.nullOr types.str);
          };
          "keyType" = mkOption {
            description = "The type of keypair Kubelet will generate for the pod.\n\nValid values are \"RSA3072\", \"RSA4096\", \"ECDSAP256\", \"ECDSAP384\",\n\"ECDSAP521\", and \"ED25519\".";
            type = types.str;
          };
          "maxExpirationSeconds" = mkOption {
            description = "maxExpirationSeconds is the maximum lifetime permitted for the\ncertificate.\n\nKubelet copies this value verbatim into the PodCertificateRequests it\ngenerates for this projection.\n\nIf omitted, kube-apiserver will set it to 86400(24 hours). kube-apiserver\nwill reject values shorter than 3600 (1 hour).  The maximum allowable\nvalue is 7862400 (91 days).\n\nThe signer implementation is then free to issue a certificate with any\nlifetime *shorter* than MaxExpirationSeconds, but no shorter than 3600\nseconds (1 hour).  This constraint is enforced by kube-apiserver.\n`kubernetes.io` signers will never issue certificates with a lifetime\nlonger than 24 hours.";
            type = (types.nullOr types.int);
          };
          "signerName" = mkOption {
            description = "Kubelet's generated CSRs will be addressed to this signer.";
            type = types.str;
          };
          "user" = mkOption {
            description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
            type = (types.nullOr types.int);
          };
          "userAnnotations" = mkOption {
            description = "userAnnotations allow pod authors to pass additional information to\nthe signer implementation.  Kubernetes does not restrict or validate this\nmetadata in any way.\n\nThese values are copied verbatim into the `spec.unverifiedUserAnnotations` field of\nthe PodCertificateRequest objects that Kubelet creates.\n\nEntries are subject to the same validation as object metadata annotations,\nwith the addition that all keys must be domain-prefixed. No restrictions\nare placed on values, except an overall size limitation on the entire field.\n\nSigners should document the keys and values they support. Signers should\ndeny requests that contain keys they do not recognize.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "certificateChainPath" = mkOverride 1002 null;
          "credentialBundlePath" = mkOverride 1002 null;
          "keyPath" = mkOverride 1002 null;
          "maxExpirationSeconds" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
          "userAnnotations" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesSecret" = {

      options = {
        "items" = mkOption {
          description = "items if unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesSecretItems"
              )
            )
          );
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "optional field specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "items" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesSecretItems" = {

      options = {
        "key" = mkOption {
          description = "key is the key to project.";
          type = types.str;
        };
        "mode" = mkOption {
          description = "mode is Optional: mode bits used to set permissions on this file.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "path is the relative path of the file to map the key to.\nMay not be an absolute path.\nMay not contain the path element '..'.\nMay not start with the string '..'.";
          type = types.str;
        };
        "user" = mkOption {
          description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "mode" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesProjectedSourcesServiceAccountToken" =
      {

        options = {
          "audience" = mkOption {
            description = "audience is the intended audience of the token. A recipient of a token\nmust identify itself with an identifier specified in the audience of the\ntoken, and otherwise should reject the token. The audience defaults to the\nidentifier of the apiserver.";
            type = (types.nullOr types.str);
          };
          "expirationSeconds" = mkOption {
            description = "expirationSeconds is the requested duration of validity of the service\naccount token. As the token approaches expiration, the kubelet volume\nplugin will proactively rotate the service account token. The kubelet will\nstart trying to rotate the token if the token is older than 80 percent of\nits time to live or if the token is older than 24 hours.Defaults to 1 hour\nand must be at least 10 minutes.";
            type = (types.nullOr types.int);
          };
          "path" = mkOption {
            description = "path is the path relative to the mount point of the file to project the\ntoken into.";
            type = types.str;
          };
          "user" = mkOption {
            description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "audience" = mkOverride 1002 null;
          "expirationSeconds" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesQuobyte" = {

      options = {
        "group" = mkOption {
          description = "group to map volume access to\nDefault is no group";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the Quobyte volume to be mounted with read-only permissions.\nDefaults to false.";
          type = (types.nullOr types.bool);
        };
        "registry" = mkOption {
          description = "registry represents a single or multiple Quobyte Registry services\nspecified as a string as host:port pair (multiple entries are separated with commas)\nwhich acts as the central registry for volumes";
          type = types.str;
        };
        "tenant" = mkOption {
          description = "tenant owning the given Quobyte volume in the Backend\nUsed with dynamically provisioned Quobyte volumes, value is set by the plugin";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "user to map volume access to\nDefaults to serivceaccount user";
          type = (types.nullOr types.str);
        };
        "volume" = mkOption {
          description = "volume is a string that references an already created Quobyte volume by name.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesRbd" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount.\nTip: Ensure that the filesystem type is supported by the host operating system.\nExamples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#rbd";
          type = (types.nullOr types.str);
        };
        "image" = mkOption {
          description = "image is the rados image name.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = types.str;
        };
        "keyring" = mkOption {
          description = "keyring is the path to key ring for RBDUser.\nDefault is /etc/ceph/keyring.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "monitors" = mkOption {
          description = "monitors is a collection of Ceph monitors.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.listOf types.str);
        };
        "pool" = mkOption {
          description = "pool is the rados pool name.\nDefault is rbd.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts.\nDefaults to false.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is name of the authentication secret for RBDUser. If provided\noverrides keyring.\nDefault is nil.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesRbdSecretRef"
            )
          );
        };
        "user" = mkOption {
          description = "user is the rados user name.\nDefault is admin.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesRbdSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesScaleIO" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\".\nDefault is \"xfs\".";
          type = (types.nullOr types.str);
        };
        "gateway" = mkOption {
          description = "gateway is the host address of the ScaleIO API Gateway.";
          type = types.str;
        };
        "protectionDomain" = mkOption {
          description = "protectionDomain is the name of the ScaleIO Protection Domain for the configured storage.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly Defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef references to the secret for ScaleIO user and other\nsensitive information. If this is not provided, Login operation will fail.";
          type = (
            submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesScaleIOSecretRef"
          );
        };
        "sslEnabled" = mkOption {
          description = "sslEnabled Flag enable/disable SSL communication with Gateway, default false";
          type = (types.nullOr types.bool);
        };
        "storageMode" = mkOption {
          description = "storageMode indicates whether the storage for a volume should be ThickProvisioned or ThinProvisioned.\nDefault is ThinProvisioned.";
          type = (types.nullOr types.str);
        };
        "storagePool" = mkOption {
          description = "storagePool is the ScaleIO Storage Pool associated with the protection domain.";
          type = (types.nullOr types.str);
        };
        "system" = mkOption {
          description = "system is the name of the storage system as configured in ScaleIO.";
          type = types.str;
        };
        "volumeName" = mkOption {
          description = "volumeName is the name of a volume already created in the ScaleIO system\nthat is associated with this volume source.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesScaleIOSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesSecret" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is Optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values\nfor mode bits. Defaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "defaultUser" = mkOption {
          description = "defaultUser is Optional: The owner UID of the created files by default.\nThe defaultUser field is only used as a fallback when the item-level user field is unset.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items If unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesSecretItems"
              )
            )
          );
        };
        "optional" = mkOption {
          description = "optional field specify whether the Secret or its keys must be defined";
          type = (types.nullOr types.bool);
        };
        "secretName" = mkOption {
          description = "secretName is the name of the secret in the pod's namespace to use.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "defaultUser" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesSecretItems" = {

      options = {
        "key" = mkOption {
          description = "key is the key to project.";
          type = types.str;
        };
        "mode" = mkOption {
          description = "mode is Optional: mode bits used to set permissions on this file.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "path is the relative path of the file to map the key to.\nMay not be an absolute path.\nMay not contain the path element '..'.\nMay not start with the string '..'.";
          type = types.str;
        };
        "user" = mkOption {
          description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "mode" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesStorageos" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef specifies the secret to use for obtaining the StorageOS API\ncredentials.  If not specified, default values will be attempted.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesStorageosSecretRef"
            )
          );
        };
        "volumeName" = mkOption {
          description = "volumeName is the human-readable name of the StorageOS volume.  Volume\nnames are only unique within a namespace.";
          type = (types.nullOr types.str);
        };
        "volumeNamespace" = mkOption {
          description = "volumeNamespace specifies the scope of the volume within StorageOS.  If no\nnamespace is specified then the Pod's namespace will be used.  This allows the\nKubernetes name scoping to be mirrored within StorageOS for tighter integration.\nSet VolumeName to any name to override the default behaviour.\nSet to \"default\" if you are not using namespaces within StorageOS.\nNamespaces that do not pre-exist within StorageOS will be created.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesStorageosSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPostVolumesVsphereVolume" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "storagePolicyID" = mkOption {
          description = "storagePolicyID is the storage Policy Based Management (SPBM) profile ID associated with the StoragePolicyName.";
          type = (types.nullOr types.str);
        };
        "storagePolicyName" = mkOption {
          description = "storagePolicyName is the storage Policy Based Management (SPBM) profile name.";
          type = (types.nullOr types.str);
        };
        "volumePath" = mkOption {
          description = "volumePath is the path that identifies vSphere volume vmdk";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "storagePolicyID" = mkOverride 1002 null;
        "storagePolicyName" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPre" = {

      options = {
        "activeDeadlineSeconds" = mkOption {
          description = "ActiveDeadlineSeconds for the hook Job. Defaults to 600.";
          type = (types.nullOr (types.withMinimum 1 types.int));
        };
        "args" = mkOption {
          description = "Args are passed to the entrypoint.";
          type = (types.nullOr (types.listOf types.str));
        };
        "backoffLimit" = mkOption {
          description = "BackoffLimit for the hook Job. Defaults to 0 (fail fast, no retries).";
          type = (types.nullOr (types.withMinimum 0 types.int));
        };
        "command" = mkOption {
          description = "Command overrides the image entrypoint.";
          type = (types.nullOr (types.listOf types.str));
        };
        "env" = mkOption {
          description = "Env are environment variables for the hook container.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnv"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "envFrom" = mkOption {
          description = "EnvFrom sources environment variables from ConfigMaps or Secrets.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvFrom")
            )
          );
        };
        "image" = mkOption {
          description = "Image is the container image to run.";
          type = (types.withMinLength 1 types.str);
        };
        "imagePullPolicy" = mkOption {
          description = "ImagePullPolicy for the hook container.";
          type = (
            types.nullOr (
              types.enum [
                "Always"
                "Never"
                "IfNotPresent"
              ]
            )
          );
        };
        "name" = mkOption {
          description = "Name is a human-readable identifier, unique within its pre/post list.";
          type = (types.withMaxLength 63 (types.withMinLength 1 types.str));
        };
        "serviceAccountName" = mkOption {
          description = "ServiceAccountName for the hook pod. Defaults to \"default\".";
          type = (types.nullOr types.str);
        };
        "volumeMounts" = mkOption {
          description = "VolumeMounts are container volume mounts.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumeMounts"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "volumes" = mkOption {
          description = "Volumes are pod-level volumes (typically Secrets / ConfigMaps).";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumes"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "activeDeadlineSeconds" = mkOverride 1002 null;
        "args" = mkOverride 1002 null;
        "backoffLimit" = mkOverride 1002 null;
        "command" = mkOverride 1002 null;
        "env" = mkOverride 1002 null;
        "envFrom" = mkOverride 1002 null;
        "imagePullPolicy" = mkOverride 1002 null;
        "serviceAccountName" = mkOverride 1002 null;
        "volumeMounts" = mkOverride 1002 null;
        "volumes" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnv" = {

      options = {
        "name" = mkOption {
          description = "Name of the environment variable.\nMay consist of any printable ASCII characters except '='.";
          type = types.str;
        };
        "value" = mkOption {
          description = "Variable references $(VAR_NAME) are expanded\nusing the previously defined environment variables in the container and\nany service environment variables. If a variable cannot be resolved,\nthe reference in the input string will be unchanged. Double $$ are reduced\nto a single $, which allows for escaping the $(VAR_NAME) syntax: i.e.\n\"$$(VAR_NAME)\" will produce the string literal \"$(VAR_NAME)\".\nEscaped references will never be expanded, regardless of whether the variable\nexists or not.\nDefaults to \"\".";
          type = (types.nullOr types.str);
        };
        "valueFrom" = mkOption {
          description = "Source for the environment variable's value. Cannot be used if value is not empty.";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFrom")
          );
        };
      };

      config = {
        "value" = mkOverride 1002 null;
        "valueFrom" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvFrom" = {

      options = {
        "configMapRef" = mkOption {
          description = "The ConfigMap to select from";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvFromConfigMapRef"
            )
          );
        };
        "prefix" = mkOption {
          description = "Optional text to prepend to the name of each environment variable.\nMay consist of any printable ASCII characters except '='.";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "The Secret to select from";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvFromSecretRef"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvFromConfigMapRef" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the ConfigMap must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvFromSecretRef" = {

      options = {
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "Specify whether the Secret must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFrom" = {

      options = {
        "configMapKeyRef" = mkOption {
          description = "Selects a key of a ConfigMap.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFromConfigMapKeyRef"
            )
          );
        };
        "fieldRef" = mkOption {
          description = "Selects a field of the pod: supports metadata.name, metadata.namespace, `metadata.labels['<KEY>']`, `metadata.annotations['<KEY>']`,\nspec.nodeName, spec.serviceAccountName, status.hostIP, status.podIP, status.podIPs.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFromFieldRef"
            )
          );
        };
        "fileKeyRef" = mkOption {
          description = "FileKeyRef selects a key of the env file.\nRequires the EnvFiles feature gate to be enabled.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFromFileKeyRef"
            )
          );
        };
        "resourceFieldRef" = mkOption {
          description = "Selects a resource of the container: only resources limits and requests\n(limits.cpu, limits.memory, limits.ephemeral-storage, requests.cpu, requests.memory and requests.ephemeral-storage) are currently supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFromResourceFieldRef"
            )
          );
        };
        "secretKeyRef" = mkOption {
          description = "Selects a key of a secret in the pod's namespace";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFromSecretKeyRef"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFromConfigMapKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key to select from the ConfigMap's Data field.\nKeys in the BinaryData field are not currently propagated to container env vars.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFromFieldRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFromFileKeyRef" = {

      options = {
        "key" = mkOption {
          description = "The key within the env file. An invalid key will prevent the pod from starting.\nThe keys defined within a source may consist of any printable ASCII characters except '='.\nDuring Alpha stage of the EnvFiles feature gate, the key size is limited to 128 characters.";
          type = types.str;
        };
        "optional" = mkOption {
          description = "Specify whether the file or its key must be defined. If the file or key\ndoes not exist, then the env var is not published.\nIf optional is set to true and the specified key does not exist,\nthe environment variable will not be set in the Pod's containers.\n\nIf optional is set to false and the specified key does not exist,\nan error will be returned during Pod creation.";
          type = (types.nullOr types.bool);
        };
        "path" = mkOption {
          description = "The path within the volume from which to select the file.\nMust be relative and may not contain the '..' path or start with '..'.";
          type = types.str;
        };
        "volumeName" = mkOption {
          description = "The name of the volume mount containing the env file.";
          type = types.str;
        };
      };

      config = {
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFromResourceFieldRef" = {

      options = {
        "containerName" = mkOption {
          description = "Container name: required for volumes, optional for env vars";
          type = (types.nullOr types.str);
        };
        "divisor" = mkOption {
          description = "Specifies the output format of the exposed resources, defaults to \"1\"";
          type = (types.nullOr (types.either types.int types.str));
        };
        "resource" = mkOption {
          description = "Required: resource to select";
          type = types.str;
        };
      };

      config = {
        "containerName" = mkOverride 1002 null;
        "divisor" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreEnvValueFromSecretKeyRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumeMounts" = {

      options = {
        "bindMountOptions" = mkOption {
          description = "bindMountOptions is the list of additional bind mount options to apply when\nmounting this volume into the container. Allowed values are noexec,\nnodev, and nosuid. These are Linux mount options and have no effect on\nWindows nodes.\nThis field is not supported with image volumes.\nThis is an alpha field and requires enabling the VolumeBindMountOptions feature gate.";
          type = (types.nullOr (types.listOf types.str));
        };
        "mountPath" = mkOption {
          description = "Path within the container at which the volume should be mounted.";
          type = types.str;
        };
        "mountPropagation" = mkOption {
          description = "mountPropagation determines how mounts are propagated from the host\nto container and the other way around.\nWhen not set, MountPropagationNone is used.\nThis field is beta in 1.10.\nWhen RecursiveReadOnly is set to IfPossible or to Enabled, MountPropagation must be None or unspecified\n(which defaults to None).";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "This must match the Name of a Volume.";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "Mounted read-only if true, read-write otherwise (false or unspecified).\nDefaults to false.";
          type = (types.nullOr types.bool);
        };
        "recursiveReadOnly" = mkOption {
          description = "RecursiveReadOnly specifies whether read-only mounts should be handled\nrecursively.\n\nIf ReadOnly is false, this field has no meaning and must be unspecified.\n\nIf ReadOnly is true, and this field is set to Disabled, the mount is not made\nrecursively read-only.  If this field is set to IfPossible, the mount is made\nrecursively read-only, if it is supported by the container runtime.  If this\nfield is set to Enabled, the mount is made recursively read-only if it is\nsupported by the container runtime, otherwise the pod will not be started and\nan error will be generated to indicate the reason.\n\nIf this field is set to IfPossible or Enabled, MountPropagation must be set to\nNone (or be unspecified, which defaults to None).\n\nIf this field is not specified, it is treated as an equivalent of Disabled.";
          type = (types.nullOr types.str);
        };
        "subPath" = mkOption {
          description = "Path within the volume from which the container's volume should be mounted.\nDefaults to \"\" (volume's root).";
          type = (types.nullOr types.str);
        };
        "subPathExpr" = mkOption {
          description = "Expanded path within the volume from which the container's volume should be mounted.\nBehaves similarly to SubPath but environment variable references $(VAR_NAME) are expanded using the container's environment.\nDefaults to \"\" (volume's root).\nSubPathExpr and SubPath are mutually exclusive.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "bindMountOptions" = mkOverride 1002 null;
        "mountPropagation" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "recursiveReadOnly" = mkOverride 1002 null;
        "subPath" = mkOverride 1002 null;
        "subPathExpr" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumes" = {

      options = {
        "awsElasticBlockStore" = mkOption {
          description = "awsElasticBlockStore represents an AWS Disk resource that is attached to a\nkubelet's host machine and then exposed to the pod.\nDeprecated: AWSElasticBlockStore is deprecated. All operations for the in-tree\nawsElasticBlockStore type are redirected to the ebs.csi.aws.com CSI driver.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesAwsElasticBlockStore"
            )
          );
        };
        "azureDisk" = mkOption {
          description = "azureDisk represents an Azure Data Disk mount on the host and bind mount to the pod.\nDeprecated: AzureDisk is deprecated. All operations for the in-tree azureDisk type\nare redirected to the disk.csi.azure.com CSI driver.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesAzureDisk"
            )
          );
        };
        "azureFile" = mkOption {
          description = "azureFile represents an Azure File Service mount on the host and bind mount to the pod.\nDeprecated: AzureFile is deprecated. All operations for the in-tree azureFile type\nare redirected to the file.csi.azure.com CSI driver.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesAzureFile"
            )
          );
        };
        "cephfs" = mkOption {
          description = "cephFS represents a Ceph FS mount on the host that shares a pod's lifetime.\nDeprecated: CephFS is deprecated and the in-tree cephfs type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCephfs"
            )
          );
        };
        "cinder" = mkOption {
          description = "cinder represents a cinder volume attached and mounted on kubelets host machine.\nDeprecated: Cinder is deprecated. All operations for the in-tree cinder type\nare redirected to the cinder.csi.openstack.org CSI driver.\nMore info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCinder"
            )
          );
        };
        "configMap" = mkOption {
          description = "configMap represents a configMap that should populate this volume";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesConfigMap"
            )
          );
        };
        "csi" = mkOption {
          description = "csi (Container Storage Interface) represents ephemeral storage that is handled by certain external CSI drivers.";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCsi")
          );
        };
        "downwardAPI" = mkOption {
          description = "downwardAPI represents downward API about the pod that should populate this volume";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesDownwardAPI"
            )
          );
        };
        "emptyDir" = mkOption {
          description = "emptyDir represents a temporary directory that shares a pod's lifetime.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEmptyDir"
            )
          );
        };
        "ephemeral" = mkOption {
          description = "ephemeral represents a volume that is handled by a cluster storage driver.\nThe volume's lifecycle is tied to the pod that defines it - it will be created before the pod starts,\nand deleted when the pod is removed.\n\nUse this if:\na) the volume is only needed while the pod runs,\nb) features of normal volumes like restoring from snapshot or capacity\n   tracking are needed,\nc) the storage driver is specified through a storage class, and\nd) the storage driver supports dynamic volume provisioning through\n   a PersistentVolumeClaim (see EphemeralVolumeSource for more\n   information on the connection between this volume type\n   and PersistentVolumeClaim).\n\nUse PersistentVolumeClaim or one of the vendor-specific\nAPIs for volumes that persist for longer than the lifecycle\nof an individual pod.\n\nUse CSI for light-weight local ephemeral volumes if the CSI driver is meant to\nbe used that way - see the documentation of the driver for\nmore information.\n\nA pod can use both types of ephemeral volumes and\npersistent volumes at the same time.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeral"
            )
          );
        };
        "fc" = mkOption {
          description = "fc represents a Fibre Channel resource that is attached to a kubelet's host machine and then exposed to the pod.";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesFc")
          );
        };
        "flexVolume" = mkOption {
          description = "flexVolume represents a generic volume resource that is\nprovisioned/attached using an exec based plugin.\nDeprecated: FlexVolume is deprecated. Consider using a CSIDriver instead.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesFlexVolume"
            )
          );
        };
        "flocker" = mkOption {
          description = "flocker represents a Flocker volume attached to a kubelet's host machine. This depends on the Flocker control service being running.\nDeprecated: Flocker is deprecated and the in-tree flocker type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesFlocker"
            )
          );
        };
        "gcePersistentDisk" = mkOption {
          description = "gcePersistentDisk represents a GCE Disk resource that is attached to a\nkubelet's host machine and then exposed to the pod.\nDeprecated: GCEPersistentDisk is deprecated. All operations for the in-tree\ngcePersistentDisk type are redirected to the pd.csi.storage.gke.io CSI driver.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesGcePersistentDisk"
            )
          );
        };
        "gitRepo" = mkOption {
          description = "gitRepo represents a git repository at a particular revision.\nDeprecated: GitRepo is deprecated. To provision a container with a git repo, mount an\nEmptyDir into an InitContainer that clones the repo using git, then mount the EmptyDir\ninto the Pod's container.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesGitRepo"
            )
          );
        };
        "glusterfs" = mkOption {
          description = "glusterfs represents a Glusterfs mount on the host that shares a pod's lifetime.\nDeprecated: Glusterfs is deprecated and the in-tree glusterfs type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesGlusterfs"
            )
          );
        };
        "hostPath" = mkOption {
          description = "hostPath represents a pre-existing file or directory on the host\nmachine that is directly exposed to the container. This is generally\nused for system agents or other privileged things that are allowed\nto see the host machine. Most containers will NOT need this.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesHostPath"
            )
          );
        };
        "image" = mkOption {
          description = "image represents an OCI object (a container image or artifact) pulled and mounted on the kubelet's host machine.\nThe volume is resolved at pod startup depending on which PullPolicy value is provided:\n\n- Always: the kubelet always attempts to pull the reference. Container creation will fail If the pull fails.\n- Never: the kubelet never pulls the reference and only uses a local image or artifact. Container creation will fail if the reference isn't present.\n- IfNotPresent: the kubelet pulls if the reference isn't already present on disk. Container creation will fail if the reference isn't present and the pull fails.\n\nThe volume gets re-resolved if the pod gets deleted and recreated, which means that new remote content will become available on pod recreation.\nA failure to resolve or pull the image during pod startup will block containers from starting and may add significant latency. Failures will be retried using normal volume backoff and will be reported on the pod reason and message.\nThe types of objects that may be mounted by this volume are defined by the container runtime implementation on a host machine and at minimum must include all valid types supported by the container image field.\nThe OCI object gets mounted in a single directory (spec.containers[*].volumeMounts.mountPath) by merging the manifest layers in the same way as for container images.\nThe volume will be mounted read-only (ro).\nSub path mounts for containers are not supported (spec.containers[*].volumeMounts.subpath) before 1.33.\nThe field spec.securityContext.fsGroupChangePolicy has no effect on this volume type.";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesImage")
          );
        };
        "iscsi" = mkOption {
          description = "iscsi represents an ISCSI Disk resource that is attached to a\nkubelet's host machine and then exposed to the pod.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes/#iscsi";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesIscsi")
          );
        };
        "name" = mkOption {
          description = "name of the volume.\nMust be a DNS_LABEL and unique within the pod.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = types.str;
        };
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host that shares a pod's lifetime\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesNfs")
          );
        };
        "persistentVolumeClaim" = mkOption {
          description = "persistentVolumeClaimVolumeSource represents a reference to a\nPersistentVolumeClaim in the same namespace.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesPersistentVolumeClaim"
            )
          );
        };
        "photonPersistentDisk" = mkOption {
          description = "photonPersistentDisk represents a PhotonController persistent disk attached and mounted on kubelets host machine.\nDeprecated: PhotonPersistentDisk is deprecated and the in-tree photonPersistentDisk type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesPhotonPersistentDisk"
            )
          );
        };
        "portworxVolume" = mkOption {
          description = "portworxVolume represents a portworx volume attached and mounted on kubelets host machine.\nDeprecated: PortworxVolume is deprecated. All operations for the in-tree portworxVolume type\nare redirected to the pxd.portworx.com CSI driver.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesPortworxVolume"
            )
          );
        };
        "projected" = mkOption {
          description = "projected items for all in one resources secrets, configmaps, and downward API";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjected"
            )
          );
        };
        "quobyte" = mkOption {
          description = "quobyte represents a Quobyte mount on the host that shares a pod's lifetime.\nDeprecated: Quobyte is deprecated and the in-tree quobyte type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesQuobyte"
            )
          );
        };
        "rbd" = mkOption {
          description = "rbd represents a Rados Block Device mount on the host that shares a pod's lifetime.\nDeprecated: RBD is deprecated and the in-tree rbd type is no longer supported.";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesRbd")
          );
        };
        "scaleIO" = mkOption {
          description = "scaleIO represents a ScaleIO persistent volume attached and mounted on Kubernetes nodes.\nDeprecated: ScaleIO is deprecated and the in-tree scaleIO type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesScaleIO"
            )
          );
        };
        "secret" = mkOption {
          description = "secret represents a secret that should populate this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesSecret"
            )
          );
        };
        "storageos" = mkOption {
          description = "storageOS represents a StorageOS volume attached and mounted on Kubernetes nodes.\nDeprecated: StorageOS is deprecated and the in-tree storageos type is no longer supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesStorageos"
            )
          );
        };
        "vsphereVolume" = mkOption {
          description = "vsphereVolume represents a vSphere volume attached and mounted on kubelets host machine.\nDeprecated: VsphereVolume is deprecated. All operations for the in-tree vsphereVolume type\nare redirected to the csi.vsphere.vmware.com CSI driver.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesVsphereVolume"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesAwsElasticBlockStore" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount.\nTip: Ensure that the filesystem type is supported by the host operating system.\nExamples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = (types.nullOr types.str);
        };
        "partition" = mkOption {
          description = "partition is the partition in the volume that you want to mount.\nIf omitted, the default is to mount by volume name.\nExamples: For volume /dev/sda1, you specify the partition as \"1\".\nSimilarly, the volume partition for /dev/sda is \"0\" (or you can leave the property empty).";
          type = (types.nullOr types.int);
        };
        "readOnly" = mkOption {
          description = "readOnly value true will force the readOnly setting in VolumeMounts.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = (types.nullOr types.bool);
        };
        "volumeID" = mkOption {
          description = "volumeID is unique ID of the persistent disk resource in AWS (Amazon EBS volume).\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "partition" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesAzureDisk" = {

      options = {
        "cachingMode" = mkOption {
          description = "cachingMode is the Host Caching mode: None, Read Only, Read Write.";
          type = (types.nullOr types.str);
        };
        "diskName" = mkOption {
          description = "diskName is the Name of the data disk in the blob storage";
          type = types.str;
        };
        "diskURI" = mkOption {
          description = "diskURI is the URI of data disk in the blob storage";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType is Filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "kind expected values are Shared: multiple blob disks per storage account  Dedicated: single blob disk per storage account  Managed: azure managed data disk (only in managed availability set). defaults to shared";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly Defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesAzureFile" = {

      options = {
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretName" = mkOption {
          description = "secretName is the  name of secret that contains Azure Storage Account Name and Key";
          type = types.str;
        };
        "shareName" = mkOption {
          description = "shareName is the azure share Name";
          type = types.str;
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCephfs" = {

      options = {
        "monitors" = mkOption {
          description = "monitors is Required: Monitors is a collection of Ceph monitors\nMore info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.listOf types.str);
        };
        "path" = mkOption {
          description = "path is Optional: Used as the mounted root, rather than the full Ceph tree, default is /";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: Defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.\nMore info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr types.bool);
        };
        "secretFile" = mkOption {
          description = "secretFile is Optional: SecretFile is the path to key ring for User, default is /etc/ceph/user.secret\nMore info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "secretRef" = mkOption {
          description = "secretRef is Optional: SecretRef is reference to the authentication secret for User, default is empty.\nMore info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCephfsSecretRef"
            )
          );
        };
        "user" = mkOption {
          description = "user is optional: User is the rados user name, default is admin\nMore info: https://examples.k8s.io/volumes/cephfs/README.md#how-to-use-it";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCephfsSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCinder" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nExamples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.\nMore info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.\nMore info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is optional: points to a secret object containing parameters used to connect\nto OpenStack.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCinderSecretRef"
            )
          );
        };
        "volumeID" = mkOption {
          description = "volumeID used to identify the volume in cinder.\nMore info: https://examples.k8s.io/mysql-cinder-pd/README.md";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
        "secretRef" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCinderSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesConfigMap" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nDefaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "defaultUser" = mkOption {
          description = "defaultUser is Optional: The owner UID of the created files by default.\nThe defaultUser field is only used as a fallback when the item-level user field is unset.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items if unspecified, each key-value pair in the Data field of the referenced\nConfigMap will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the ConfigMap,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesConfigMapItems"
              )
            )
          );
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "optional specify whether the ConfigMap or its keys must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "defaultUser" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesConfigMapItems" = {

      options = {
        "key" = mkOption {
          description = "key is the key to project.";
          type = types.str;
        };
        "mode" = mkOption {
          description = "mode is Optional: mode bits used to set permissions on this file.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "path is the relative path of the file to map the key to.\nMay not be an absolute path.\nMay not contain the path element '..'.\nMay not start with the string '..'.";
          type = types.str;
        };
        "user" = mkOption {
          description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "mode" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCsi" = {

      options = {
        "driver" = mkOption {
          description = "driver is the name of the CSI driver that handles this volume.\nConsult with your admin for the correct name as registered in the cluster.";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType to mount. Ex. \"ext4\", \"xfs\", \"ntfs\".\nIf not provided, the empty value is passed to the associated CSI driver\nwhich will determine the default filesystem to apply.";
          type = (types.nullOr types.str);
        };
        "nodePublishSecretRef" = mkOption {
          description = "nodePublishSecretRef is a reference to the secret object containing\nsensitive information to pass to the CSI driver to complete the CSI\nNodePublishVolume and NodeUnpublishVolume calls.\nThis field is optional, and  may be empty if no secret is required. If the\nsecret object contains more than one secret, all secret references are passed.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCsiNodePublishSecretRef"
            )
          );
        };
        "readOnly" = mkOption {
          description = "readOnly specifies a read-only configuration for the volume.\nDefaults to false (read/write).";
          type = (types.nullOr types.bool);
        };
        "volumeAttributes" = mkOption {
          description = "volumeAttributes stores driver-specific properties that are passed to the CSI\ndriver. Consult your driver's documentation for supported values.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesCsiNodePublishSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesDownwardAPI" = {

      options = {
        "defaultMode" = mkOption {
          description = "Optional: mode bits to use on created files by default. Must be a\nOptional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nDefaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "defaultUser" = mkOption {
          description = "defaultUser is Optional: The owner UID of the created files by default.\nThe defaultUser field is only used as a fallback when the item-level user field is unset.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "Items is a list of downward API volume file";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesDownwardAPIItems"
              )
            )
          );
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "defaultUser" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesDownwardAPIItems" = {

      options = {
        "fieldRef" = mkOption {
          description = "Required: Selects a field of the pod: only annotations, labels, name, namespace and uid are supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesDownwardAPIItemsFieldRef"
            )
          );
        };
        "mode" = mkOption {
          description = "Optional: mode bits used to set permissions on this file, must be an octal value\nbetween 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "Required: Path is  the relative path name of the file to be created. Must not be absolute or contain the '..' path. Must be utf-8 encoded. The first item of the relative path must not start with '..'";
          type = types.str;
        };
        "resourceFieldRef" = mkOption {
          description = "Selects a resource of the container: only resources limits and requests\n(limits.cpu, limits.memory, requests.cpu and requests.memory) are currently supported.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesDownwardAPIItemsResourceFieldRef"
            )
          );
        };
        "user" = mkOption {
          description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "fieldRef" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "resourceFieldRef" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesDownwardAPIItemsFieldRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesDownwardAPIItemsResourceFieldRef" =
      {

        options = {
          "containerName" = mkOption {
            description = "Container name: required for volumes, optional for env vars";
            type = (types.nullOr types.str);
          };
          "divisor" = mkOption {
            description = "Specifies the output format of the exposed resources, defaults to \"1\"";
            type = (types.nullOr (types.either types.int types.str));
          };
          "resource" = mkOption {
            description = "Required: resource to select";
            type = types.str;
          };
        };

        config = {
          "containerName" = mkOverride 1002 null;
          "divisor" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEmptyDir" = {

      options = {
        "medium" = mkOption {
          description = "medium represents what type of storage medium should back this directory.\nThe default is \"\" which means to use the node's default medium.\nMust be an empty string (default) or Memory.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir";
          type = (types.nullOr types.str);
        };
        "mode" = mkOption {
          description = "mode specifies the permission bits for the emptyDir directory, in numeric\nnotation (e.g., 0755, 01777). Must be a value between 0000 and 01777.\nIf not specified, defaults to 0777.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup. If fsGroup is specified, the fsGroup permissions\nwill override the mode specified here.\nThis field has no effect on Windows.\nThis field is alpha and requires EmptyDirVolumeMode featuregate to be enabled.";
          type = (types.nullOr types.int);
        };
        "sizeLimit" = mkOption {
          description = "sizeLimit is the total amount of local storage required for this EmptyDir volume.\nThe size limit is also applicable for memory medium.\nThe maximum usage on memory medium EmptyDir would be the minimum value between\nthe SizeLimit specified here and the sum of memory limits of all containers in a pod.\nThe default is nil which means that the limit is undefined.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir";
          type = (types.nullOr (types.either types.int types.str));
        };
      };

      config = {
        "medium" = mkOverride 1002 null;
        "mode" = mkOverride 1002 null;
        "sizeLimit" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeral" = {

      options = {
        "volumeClaimTemplate" = mkOption {
          description = "Will be used to create a stand-alone PVC to provision the volume.\nThe pod in which this EphemeralVolumeSource is embedded will be the\nowner of the PVC, i.e. the PVC will be deleted together with the\npod.  The name of the PVC will be `<pod name>-<volume name>` where\n`<volume name>` is the name from the `PodSpec.Volumes` array\nentry. Pod validation will reject the pod if the concatenated name\nis not valid for a PVC (for example, too long).\n\nAn existing PVC with that name that is not owned by the pod\nwill *not* be used for the pod to avoid using an unrelated\nvolume by mistake. Starting the pod is then blocked until\nthe unrelated PVC is removed. If such a pre-created PVC is\nmeant to be used by the pod, the PVC has to updated with an\nowner reference to the pod once the pod exists. Normally\nthis should not be necessary, but it may be useful when\nmanually reconstructing a broken cluster.\n\nThis field is read-only and no changes will be made by Kubernetes\nto the PVC after it has been created.\n\nRequired, must not be nil.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplate"
            )
          );
        };
      };

      config = {
        "volumeClaimTemplate" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplate" = {

      options = {
        "metadata" = mkOption {
          description = "May contain labels and annotations that will be copied into the PVC\nwhen creating it. No other fields are allowed and will be rejected during\nvalidation.";
          type = (types.nullOr types.attrs);
        };
        "spec" = mkOption {
          description = "The specification for the PersistentVolumeClaim. The entire content is\ncopied unchanged into the PVC that gets created from this\ntemplate. The same fields as in a PersistentVolumeClaim\nare also valid here.";
          type = (
            submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpec"
          );
        };
      };

      config = {
        "metadata" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpec" =
      {

        options = {
          "accessModes" = mkOption {
            description = "accessModes contains the desired access modes the volume should have.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes-1";
            type = (types.nullOr (types.listOf types.str));
          };
          "dataSource" = mkOption {
            description = "dataSource field can be used to specify either:\n* An existing VolumeSnapshot object (snapshot.storage.k8s.io/VolumeSnapshot)\n* An existing PVC (PersistentVolumeClaim)\nIf the provisioner or an external controller can support the specified data source,\nit will create a new volume based on the contents of the specified data source.\ndataSource contents will be copied to dataSourceRef, and dataSourceRef contents will be\ncopied to dataSource when dataSourceRef.namespace is not specified.\nIf the namespace is specified, then dataSourceRef will not be copied to dataSource.";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpecDataSource"
              )
            );
          };
          "dataSourceRef" = mkOption {
            description = "dataSourceRef specifies the object from which to populate the volume with data, if a non-empty\nvolume is desired. This may be any object from a non-empty API group (non\ncore object) or a PersistentVolumeClaim object.\nWhen this field is specified, volume binding will only succeed if the type of\nthe specified object matches some installed volume populator or dynamic\nprovisioner.\nThis field will replace the functionality of the dataSource field and as such\nif both fields are non-empty, they must have the same value. For backwards\ncompatibility, when namespace isn't specified in dataSourceRef,\nboth fields (dataSource and dataSourceRef) will be set to the same\nvalue automatically if one of them is empty and the other is non-empty.\nWhen namespace is specified in dataSourceRef,\ndataSource isn't set to the same value and must be empty.\nThere are three important differences between dataSource and dataSourceRef:\n* While dataSource only allows two specific types of objects, dataSourceRef\n  allows any non-core object, as well as PersistentVolumeClaim objects.\n* While dataSource ignores disallowed values (dropping them), dataSourceRef\n  preserves all values, and generates an error if a disallowed value is\n  specified.\n* While dataSource only allows local objects, dataSourceRef allows objects\n  in any namespaces.\n(Alpha) Using the namespace field of dataSourceRef requires the CrossNamespaceVolumeDataSource feature gate to be enabled.";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpecDataSourceRef"
              )
            );
          };
          "resources" = mkOption {
            description = "resources represents the minimum resources the volume should have.\nUsers are allowed to specify resource requirements\nthat are lower than previous value but must still be higher than capacity recorded in the\nstatus field of the claim.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#resources";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpecResources"
              )
            );
          };
          "selector" = mkOption {
            description = "selector is a label query over volumes to consider for binding.";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpecSelector"
              )
            );
          };
          "storageClassName" = mkOption {
            description = "storageClassName is the name of the StorageClass required by the claim.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#class-1";
            type = (types.nullOr types.str);
          };
          "volumeAttributesClassName" = mkOption {
            description = "volumeAttributesClassName may be used to set the VolumeAttributesClass used by this claim.\nIf specified, the CSI driver will create or update the volume with the attributes defined\nin the corresponding VolumeAttributesClass. This has a different purpose than storageClassName,\nit can be changed after the claim is created. An empty string or nil value indicates that no\nVolumeAttributesClass will be applied to the claim. If the claim enters an Infeasible error state,\nthis field can be reset to its previous value (including nil) to cancel the modification.\nIf the resource referred to by volumeAttributesClass does not exist, this PersistentVolumeClaim will be\nset to a Pending state, as reflected by the modifyVolumeStatus field, until such as a resource\nexists.\nMore info: https://kubernetes.io/docs/concepts/storage/volume-attributes-classes/";
            type = (types.nullOr types.str);
          };
          "volumeMode" = mkOption {
            description = "volumeMode defines what type of volume is required by the claim.\nValue of Filesystem is implied when not included in claim spec.";
            type = (types.nullOr types.str);
          };
          "volumeName" = mkOption {
            description = "volumeName is the binding reference to the PersistentVolume backing this claim.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpecDataSource" =
      {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpecDataSourceRef" =
      {

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
          "namespace" = mkOption {
            description = "Namespace is the namespace of resource being referenced\nNote that when a namespace is specified, a gateway.networking.k8s.io/ReferenceGrant object is required in the referent namespace to allow that namespace's owner to accept the reference. See the ReferenceGrant documentation for details.\n(Alpha) This field requires the CrossNamespaceVolumeDataSource feature gate to be enabled.";
            type = (types.nullOr types.str);
          };
        };

        config = {
          "apiGroup" = mkOverride 1002 null;
          "namespace" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpecResources" =
      {

        options = {
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
          "limits" = mkOverride 1002 null;
          "requests" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpecSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpecSelectorMatchExpressions"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesEphemeralVolumeClaimTemplateSpecSelectorMatchExpressions" =
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesFc" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "lun" = mkOption {
          description = "lun is Optional: FC target lun number";
          type = (types.nullOr types.int);
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: Defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "targetWWNs" = mkOption {
          description = "targetWWNs is Optional: FC target worldwide names (WWNs)";
          type = (types.nullOr (types.listOf types.str));
        };
        "wwids" = mkOption {
          description = "wwids Optional: FC volume world wide identifiers (wwids)\nEither wwids or combination of targetWWNs and lun must be set, but not both simultaneously.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesFlexVolume" = {

      options = {
        "driver" = mkOption {
          description = "driver is the name of the driver to use for this volume.";
          type = types.str;
        };
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". The default filesystem depends on FlexVolume script.";
          type = (types.nullOr types.str);
        };
        "options" = mkOption {
          description = "options is Optional: this field holds extra command options if any.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "readOnly" = mkOption {
          description = "readOnly is Optional: defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is Optional: secretRef is reference to the secret object containing\nsensitive information to pass to the plugin scripts. This may be\nempty if no secret object is specified. If the secret object\ncontains more than one secret, all secrets are passed to the plugin\nscripts.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesFlexVolumeSecretRef"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesFlexVolumeSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesFlocker" = {

      options = {
        "datasetName" = mkOption {
          description = "datasetName is Name of the dataset stored as metadata -> name on the dataset for Flocker\nshould be considered as deprecated";
          type = (types.nullOr types.str);
        };
        "datasetUUID" = mkOption {
          description = "datasetUUID is the UUID of the dataset. This is unique identifier of a Flocker dataset";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "datasetName" = mkOverride 1002 null;
        "datasetUUID" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesGcePersistentDisk" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is filesystem type of the volume that you want to mount.\nTip: Ensure that the filesystem type is supported by the host operating system.\nExamples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr types.str);
        };
        "partition" = mkOption {
          description = "partition is the partition in the volume that you want to mount.\nIf omitted, the default is to mount by volume name.\nExamples: For volume /dev/sda1, you specify the partition as \"1\".\nSimilarly, the volume partition for /dev/sda is \"0\" (or you can leave the property empty).\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr types.int);
        };
        "pdName" = mkOption {
          description = "pdName is unique name of the PD resource in GCE. Used to identify the disk in GCE.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts.\nDefaults to false.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "partition" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesGitRepo" = {

      options = {
        "directory" = mkOption {
          description = "directory is the target directory name.\nMust not contain or start with '..'.  If '.' is supplied, the volume directory will be the\ngit repository.  Otherwise, if specified, the volume will contain the git repository in\nthe subdirectory with the given name.";
          type = (types.nullOr types.str);
        };
        "repository" = mkOption {
          description = "repository is the URL";
          type = types.str;
        };
        "revision" = mkOption {
          description = "revision is the commit hash for the specified revision.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "directory" = mkOverride 1002 null;
        "revision" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesGlusterfs" = {

      options = {
        "endpoints" = mkOption {
          description = "endpoints is the endpoint name that details Glusterfs topology.";
          type = types.str;
        };
        "path" = mkOption {
          description = "path is the Glusterfs volume path.\nMore info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the Glusterfs volume to be mounted with read-only permissions.\nDefaults to false.\nMore info: https://examples.k8s.io/volumes/glusterfs/README.md#create-a-pod";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesHostPath" = {

      options = {
        "path" = mkOption {
          description = "path of the directory on the host.\nIf the path is a symlink, it will follow the link to the real path.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath";
          type = types.str;
        };
        "type" = mkOption {
          description = "type for HostPath Volume\nDefaults to \"\"\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "type" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesImage" = {

      options = {
        "pullPolicy" = mkOption {
          description = "Policy for pulling OCI objects. Possible values are:\nAlways: the kubelet always attempts to pull the reference. Container creation will fail If the pull fails.\nNever: the kubelet never pulls the reference and only uses a local image or artifact. Container creation will fail if the reference isn't present.\nIfNotPresent: the kubelet pulls if the reference isn't already present on disk. Container creation will fail if the reference isn't present and the pull fails.\nDefaults to Always if :latest tag is specified, or IfNotPresent otherwise.";
          type = (types.nullOr types.str);
        };
        "reference" = mkOption {
          description = "Required: Image or artifact reference to be used.\nBehaves in the same way as pod.spec.containers[*].image.\nPull secrets will be assembled in the same way as for the container image by looking up node credentials, SA image pull secrets, and pod spec image pull secrets.\nMore info: https://kubernetes.io/docs/concepts/containers/images\nThis field is optional to allow higher level config management to default or override\ncontainer images in workload controllers like Deployments and StatefulSets.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "pullPolicy" = mkOverride 1002 null;
        "reference" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesIscsi" = {

      options = {
        "chapAuthDiscovery" = mkOption {
          description = "chapAuthDiscovery defines whether support iSCSI Discovery CHAP authentication";
          type = (types.nullOr types.bool);
        };
        "chapAuthSession" = mkOption {
          description = "chapAuthSession defines whether support iSCSI Session CHAP authentication";
          type = (types.nullOr types.bool);
        };
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount.\nTip: Ensure that the filesystem type is supported by the host operating system.\nExamples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#iscsi";
          type = (types.nullOr types.str);
        };
        "initiatorName" = mkOption {
          description = "initiatorName is the custom iSCSI Initiator Name.\nIf initiatorName is specified with iscsiInterface simultaneously, new iSCSI interface\n<target portal>:<volume name> will be created for the connection.";
          type = (types.nullOr types.str);
        };
        "iqn" = mkOption {
          description = "iqn is the target iSCSI Qualified Name.";
          type = types.str;
        };
        "iscsiInterface" = mkOption {
          description = "iscsiInterface is the interface Name that uses an iSCSI transport.\nDefaults to 'default' (tcp).";
          type = (types.nullOr types.str);
        };
        "lun" = mkOption {
          description = "lun represents iSCSI Target Lun number.";
          type = types.int;
        };
        "portals" = mkOption {
          description = "portals is the iSCSI Target Portal List. The portal is either an IP or ip_addr:port if the port\nis other than default (typically TCP ports 860 and 3260).";
          type = (types.nullOr (types.listOf types.str));
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts.\nDefaults to false.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is the CHAP Secret for iSCSI target and initiator authentication";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesIscsiSecretRef"
            )
          );
        };
        "targetPortal" = mkOption {
          description = "targetPortal is iSCSI Target Portal. The Portal is either an IP or ip_addr:port if the port\nis other than default (typically TCP ports 860 and 3260).";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesIscsiSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesNfs" = {

      options = {
        "path" = mkOption {
          description = "path that is exported by the NFS server.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the NFS export to be mounted with read-only permissions.\nDefaults to false.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (types.nullOr types.bool);
        };
        "server" = mkOption {
          description = "server is the hostname or IP address of the NFS server.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = types.str;
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesPersistentVolumeClaim" = {

      options = {
        "claimName" = mkOption {
          description = "claimName is the name of a PersistentVolumeClaim in the same namespace as the pod using this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims";
          type = types.str;
        };
        "readOnly" = mkOption {
          description = "readOnly Will force the ReadOnly setting in VolumeMounts.\nDefault false.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesPhotonPersistentDisk" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "pdID" = mkOption {
          description = "pdID is the ID that identifies Photon Controller persistent disk";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesPortworxVolume" = {

      options = {
        "fsType" = mkOption {
          description = "fSType represents the filesystem type to mount\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "volumeID" = mkOption {
          description = "volumeID uniquely identifies a Portworx volume";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "readOnly" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjected" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode are the mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "defaultUser" = mkOption {
          description = "defaultUser is Optional: The owner UID of the created files by default.\nThe defaultUser field is only used as a fallback when the item-level user field is unset.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
        "sources" = mkOption {
          description = "sources is the list of volume projections. Each entry in this list\nhandles one source.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSources"
              )
            )
          );
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "defaultUser" = mkOverride 1002 null;
        "sources" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSources" = {

      options = {
        "clusterTrustBundle" = mkOption {
          description = "ClusterTrustBundle allows a pod to access the `.spec.trustBundle` field\nof ClusterTrustBundle objects in an auto-updating file.\n\nAlpha, gated by the ClusterTrustBundleProjection feature gate.\n\nClusterTrustBundle objects can either be selected by name, or by the\ncombination of signer name and a label selector.\n\nKubelet performs aggressive normalization of the PEM contents written\ninto the pod filesystem.  Esoteric PEM features such as inter-block\ncomments and block headers are stripped.  Certificates are deduplicated.\nThe ordering of certificates within the file is arbitrary, and Kubelet\nmay change the order over time.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesClusterTrustBundle"
            )
          );
        };
        "configMap" = mkOption {
          description = "configMap information about the configMap data to project";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesConfigMap"
            )
          );
        };
        "downwardAPI" = mkOption {
          description = "downwardAPI information about the downwardAPI data to project";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesDownwardAPI"
            )
          );
        };
        "podCertificate" = mkOption {
          description = "Projects an auto-rotating credential bundle (private key and certificate\nchain) that the pod can use either as a TLS client or server.\n\nKubelet generates a private key and uses it to send a\nPodCertificateRequest to the named signer.  Once the signer approves the\nrequest and issues a certificate chain, Kubelet writes the key and\ncertificate chain to the pod filesystem.  The pod does not start until\ncertificates have been issued for each podCertificate projected volume\nsource in its spec.\n\nKubelet will begin trying to rotate the certificate at the time indicated\nby the signer using the PodCertificateRequest.Status.BeginRefreshAt\ntimestamp.\n\nKubelet can write a single file, indicated by the credentialBundlePath\nfield, or separate files, indicated by the keyPath and\ncertificateChainPath fields.\n\nThe credential bundle is a single file in PEM format.  The first PEM\nentry is the private key (in PKCS#8 format), and the remaining PEM\nentries are the certificate chain issued by the signer (typically,\nsigners will return their certificate chain in leaf-to-root order).\n\nPrefer using the credential bundle format, since your application code\ncan read it atomically.  If you use keyPath and certificateChainPath,\nyour application must make two separate file reads. If these coincide\nwith a certificate rotation, it is possible that the private key and leaf\ncertificate you read may not correspond to each other.  Your application\nwill need to check for this condition, and re-read until they are\nconsistent.\n\nThe named signer controls chooses the format of the certificate it\nissues; consult the signer implementation's documentation to learn how to\nuse the certificates it issues.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesPodCertificate"
            )
          );
        };
        "secret" = mkOption {
          description = "secret information about the secret data to project";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesSecret"
            )
          );
        };
        "serviceAccountToken" = mkOption {
          description = "serviceAccountToken is information about the serviceAccountToken data to project";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesServiceAccountToken"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesClusterTrustBundle" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "Select all ClusterTrustBundles that match this label selector.  Only has\neffect if signerName is set.  Mutually-exclusive with name.  If unset,\ninterpreted as \"match nothing\".  If set but empty, interpreted as \"match\neverything\".";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesClusterTrustBundleLabelSelector"
              )
            );
          };
          "name" = mkOption {
            description = "Select a single ClusterTrustBundle by object name.  Mutually-exclusive\nwith signerName and labelSelector.";
            type = (types.nullOr types.str);
          };
          "optional" = mkOption {
            description = "If true, don't block pod startup if the referenced ClusterTrustBundle(s)\naren't available.  If using name, then the named ClusterTrustBundle is\nallowed not to exist.  If using signerName, then the combination of\nsignerName and labelSelector is allowed to match zero\nClusterTrustBundles.";
            type = (types.nullOr types.bool);
          };
          "path" = mkOption {
            description = "Relative path from the volume root to write the bundle.";
            type = types.str;
          };
          "signerName" = mkOption {
            description = "Select all ClusterTrustBundles that match this signer name.\nMutually-exclusive with name.  The contents of all selected\nClusterTrustBundles will be unified and deduplicated.";
            type = (types.nullOr types.str);
          };
          "user" = mkOption {
            description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "labelSelector" = mkOverride 1002 null;
          "name" = mkOverride 1002 null;
          "optional" = mkOverride 1002 null;
          "signerName" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesClusterTrustBundleLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesClusterTrustBundleLabelSelectorMatchExpressions"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesClusterTrustBundleLabelSelectorMatchExpressions" =
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesConfigMap" = {

      options = {
        "items" = mkOption {
          description = "items if unspecified, each key-value pair in the Data field of the referenced\nConfigMap will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the ConfigMap,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesConfigMapItems"
              )
            )
          );
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "optional specify whether the ConfigMap or its keys must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "items" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesConfigMapItems" =
      {

        options = {
          "key" = mkOption {
            description = "key is the key to project.";
            type = types.str;
          };
          "mode" = mkOption {
            description = "mode is Optional: mode bits used to set permissions on this file.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
            type = (types.nullOr types.int);
          };
          "path" = mkOption {
            description = "path is the relative path of the file to map the key to.\nMay not be an absolute path.\nMay not contain the path element '..'.\nMay not start with the string '..'.";
            type = types.str;
          };
          "user" = mkOption {
            description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "mode" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesDownwardAPI" = {

      options = {
        "items" = mkOption {
          description = "Items is a list of DownwardAPIVolume file";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesDownwardAPIItems"
              )
            )
          );
        };
      };

      config = {
        "items" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesDownwardAPIItems" =
      {

        options = {
          "fieldRef" = mkOption {
            description = "Required: Selects a field of the pod: only annotations, labels, name, namespace and uid are supported.";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesDownwardAPIItemsFieldRef"
              )
            );
          };
          "mode" = mkOption {
            description = "Optional: mode bits used to set permissions on this file, must be an octal value\nbetween 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
            type = (types.nullOr types.int);
          };
          "path" = mkOption {
            description = "Required: Path is  the relative path name of the file to be created. Must not be absolute or contain the '..' path. Must be utf-8 encoded. The first item of the relative path must not start with '..'";
            type = types.str;
          };
          "resourceFieldRef" = mkOption {
            description = "Selects a resource of the container: only resources limits and requests\n(limits.cpu, limits.memory, requests.cpu and requests.memory) are currently supported.";
            type = (
              types.nullOr (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesDownwardAPIItemsResourceFieldRef"
              )
            );
          };
          "user" = mkOption {
            description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "fieldRef" = mkOverride 1002 null;
          "mode" = mkOverride 1002 null;
          "resourceFieldRef" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesDownwardAPIItemsFieldRef" =
      {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesDownwardAPIItemsResourceFieldRef" =
      {

        options = {
          "containerName" = mkOption {
            description = "Container name: required for volumes, optional for env vars";
            type = (types.nullOr types.str);
          };
          "divisor" = mkOption {
            description = "Specifies the output format of the exposed resources, defaults to \"1\"";
            type = (types.nullOr (types.either types.int types.str));
          };
          "resource" = mkOption {
            description = "Required: resource to select";
            type = types.str;
          };
        };

        config = {
          "containerName" = mkOverride 1002 null;
          "divisor" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesPodCertificate" =
      {

        options = {
          "certificateChainPath" = mkOption {
            description = "Write the certificate chain at this path in the projected volume.\n\nMost applications should use credentialBundlePath.  When using keyPath\nand certificateChainPath, your application needs to check that the key\nand leaf certificate are consistent, because it is possible to read the\nfiles mid-rotation.";
            type = (types.nullOr types.str);
          };
          "credentialBundlePath" = mkOption {
            description = "Write the credential bundle at this path in the projected volume.\n\nThe credential bundle is a single file that contains multiple PEM blocks.\nThe first PEM block is a PRIVATE KEY block, containing a PKCS#8 private\nkey.\n\nThe remaining blocks are CERTIFICATE blocks, containing the issued\ncertificate chain from the signer (leaf and any intermediates).\n\nUsing credentialBundlePath lets your Pod's application code make a single\natomic read that retrieves a consistent key and certificate chain.  If you\nproject them to separate files, your application code will need to\nadditionally check that the leaf certificate was issued to the key.";
            type = (types.nullOr types.str);
          };
          "keyPath" = mkOption {
            description = "Write the key at this path in the projected volume.\n\nMost applications should use credentialBundlePath.  When using keyPath\nand certificateChainPath, your application needs to check that the key\nand leaf certificate are consistent, because it is possible to read the\nfiles mid-rotation.";
            type = (types.nullOr types.str);
          };
          "keyType" = mkOption {
            description = "The type of keypair Kubelet will generate for the pod.\n\nValid values are \"RSA3072\", \"RSA4096\", \"ECDSAP256\", \"ECDSAP384\",\n\"ECDSAP521\", and \"ED25519\".";
            type = types.str;
          };
          "maxExpirationSeconds" = mkOption {
            description = "maxExpirationSeconds is the maximum lifetime permitted for the\ncertificate.\n\nKubelet copies this value verbatim into the PodCertificateRequests it\ngenerates for this projection.\n\nIf omitted, kube-apiserver will set it to 86400(24 hours). kube-apiserver\nwill reject values shorter than 3600 (1 hour).  The maximum allowable\nvalue is 7862400 (91 days).\n\nThe signer implementation is then free to issue a certificate with any\nlifetime *shorter* than MaxExpirationSeconds, but no shorter than 3600\nseconds (1 hour).  This constraint is enforced by kube-apiserver.\n`kubernetes.io` signers will never issue certificates with a lifetime\nlonger than 24 hours.";
            type = (types.nullOr types.int);
          };
          "signerName" = mkOption {
            description = "Kubelet's generated CSRs will be addressed to this signer.";
            type = types.str;
          };
          "user" = mkOption {
            description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
            type = (types.nullOr types.int);
          };
          "userAnnotations" = mkOption {
            description = "userAnnotations allow pod authors to pass additional information to\nthe signer implementation.  Kubernetes does not restrict or validate this\nmetadata in any way.\n\nThese values are copied verbatim into the `spec.unverifiedUserAnnotations` field of\nthe PodCertificateRequest objects that Kubelet creates.\n\nEntries are subject to the same validation as object metadata annotations,\nwith the addition that all keys must be domain-prefixed. No restrictions\nare placed on values, except an overall size limitation on the entire field.\n\nSigners should document the keys and values they support. Signers should\ndeny requests that contain keys they do not recognize.";
            type = (types.nullOr (types.attrsOf types.str));
          };
        };

        config = {
          "certificateChainPath" = mkOverride 1002 null;
          "credentialBundlePath" = mkOverride 1002 null;
          "keyPath" = mkOverride 1002 null;
          "maxExpirationSeconds" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
          "userAnnotations" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesSecret" = {

      options = {
        "items" = mkOption {
          description = "items if unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesSecretItems"
              )
            )
          );
        };
        "name" = mkOption {
          description = "Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names";
          type = (types.nullOr types.str);
        };
        "optional" = mkOption {
          description = "optional field specify whether the Secret or its key must be defined";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "items" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesSecretItems" = {

      options = {
        "key" = mkOption {
          description = "key is the key to project.";
          type = types.str;
        };
        "mode" = mkOption {
          description = "mode is Optional: mode bits used to set permissions on this file.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "path is the relative path of the file to map the key to.\nMay not be an absolute path.\nMay not contain the path element '..'.\nMay not start with the string '..'.";
          type = types.str;
        };
        "user" = mkOption {
          description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "mode" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesProjectedSourcesServiceAccountToken" =
      {

        options = {
          "audience" = mkOption {
            description = "audience is the intended audience of the token. A recipient of a token\nmust identify itself with an identifier specified in the audience of the\ntoken, and otherwise should reject the token. The audience defaults to the\nidentifier of the apiserver.";
            type = (types.nullOr types.str);
          };
          "expirationSeconds" = mkOption {
            description = "expirationSeconds is the requested duration of validity of the service\naccount token. As the token approaches expiration, the kubelet volume\nplugin will proactively rotate the service account token. The kubelet will\nstart trying to rotate the token if the token is older than 80 percent of\nits time to live or if the token is older than 24 hours.Defaults to 1 hour\nand must be at least 10 minutes.";
            type = (types.nullOr types.int);
          };
          "path" = mkOption {
            description = "path is the path relative to the mount point of the file to project the\ntoken into.";
            type = types.str;
          };
          "user" = mkOption {
            description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
            type = (types.nullOr types.int);
          };
        };

        config = {
          "audience" = mkOverride 1002 null;
          "expirationSeconds" = mkOverride 1002 null;
          "user" = mkOverride 1002 null;
        };

      };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesQuobyte" = {

      options = {
        "group" = mkOption {
          description = "group to map volume access to\nDefault is no group";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the Quobyte volume to be mounted with read-only permissions.\nDefaults to false.";
          type = (types.nullOr types.bool);
        };
        "registry" = mkOption {
          description = "registry represents a single or multiple Quobyte Registry services\nspecified as a string as host:port pair (multiple entries are separated with commas)\nwhich acts as the central registry for volumes";
          type = types.str;
        };
        "tenant" = mkOption {
          description = "tenant owning the given Quobyte volume in the Backend\nUsed with dynamically provisioned Quobyte volumes, value is set by the plugin";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "user to map volume access to\nDefaults to serivceaccount user";
          type = (types.nullOr types.str);
        };
        "volume" = mkOption {
          description = "volume is a string that references an already created Quobyte volume by name.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesRbd" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type of the volume that you want to mount.\nTip: Ensure that the filesystem type is supported by the host operating system.\nExamples: \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#rbd";
          type = (types.nullOr types.str);
        };
        "image" = mkOption {
          description = "image is the rados image name.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = types.str;
        };
        "keyring" = mkOption {
          description = "keyring is the path to key ring for RBDUser.\nDefault is /etc/ceph/keyring.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "monitors" = mkOption {
          description = "monitors is a collection of Ceph monitors.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.listOf types.str);
        };
        "pool" = mkOption {
          description = "pool is the rados pool name.\nDefault is rbd.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly here will force the ReadOnly setting in VolumeMounts.\nDefaults to false.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef is name of the authentication secret for RBDUser. If provided\noverrides keyring.\nDefault is nil.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesRbdSecretRef"
            )
          );
        };
        "user" = mkOption {
          description = "user is the rados user name.\nDefault is admin.\nMore info: https://examples.k8s.io/volumes/rbd/README.md#how-to-use-it";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesRbdSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesScaleIO" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\".\nDefault is \"xfs\".";
          type = (types.nullOr types.str);
        };
        "gateway" = mkOption {
          description = "gateway is the host address of the ScaleIO API Gateway.";
          type = types.str;
        };
        "protectionDomain" = mkOption {
          description = "protectionDomain is the name of the ScaleIO Protection Domain for the configured storage.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly Defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef references to the secret for ScaleIO user and other\nsensitive information. If this is not provided, Login operation will fail.";
          type = (
            submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesScaleIOSecretRef"
          );
        };
        "sslEnabled" = mkOption {
          description = "sslEnabled Flag enable/disable SSL communication with Gateway, default false";
          type = (types.nullOr types.bool);
        };
        "storageMode" = mkOption {
          description = "storageMode indicates whether the storage for a volume should be ThickProvisioned or ThinProvisioned.\nDefault is ThinProvisioned.";
          type = (types.nullOr types.str);
        };
        "storagePool" = mkOption {
          description = "storagePool is the ScaleIO Storage Pool associated with the protection domain.";
          type = (types.nullOr types.str);
        };
        "system" = mkOption {
          description = "system is the name of the storage system as configured in ScaleIO.";
          type = types.str;
        };
        "volumeName" = mkOption {
          description = "volumeName is the name of a volume already created in the ScaleIO system\nthat is associated with this volume source.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesScaleIOSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesSecret" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is Optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values\nfor mode bits. Defaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "defaultUser" = mkOption {
          description = "defaultUser is Optional: The owner UID of the created files by default.\nThe defaultUser field is only used as a fallback when the item-level user field is unset.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items If unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesSecretItems"
              )
            )
          );
        };
        "optional" = mkOption {
          description = "optional field specify whether the Secret or its keys must be defined";
          type = (types.nullOr types.bool);
        };
        "secretName" = mkOption {
          description = "secretName is the name of the secret in the pod's namespace to use.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "defaultMode" = mkOverride 1002 null;
        "defaultUser" = mkOverride 1002 null;
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesSecretItems" = {

      options = {
        "key" = mkOption {
          description = "key is the key to project.";
          type = types.str;
        };
        "mode" = mkOption {
          description = "mode is Optional: mode bits used to set permissions on this file.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values for mode bits.\nIf not specified, the volume defaultMode will be used.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "path" = mkOption {
          description = "path is the relative path of the file to map the key to.\nMay not be an absolute path.\nMay not contain the path element '..'.\nMay not start with the string '..'.";
          type = types.str;
        };
        "user" = mkOption {
          description = "user is Optional: The owner UID of the created file.\nIf specified, the item-level user field takes precedence over defaultUser.\n(Alpha) This field requires the AtomicWriteVolumeUserFields feature gate to be enabled.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "mode" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesStorageos" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is the filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "readOnly" = mkOption {
          description = "readOnly defaults to false (read/write). ReadOnly here will force\nthe ReadOnly setting in VolumeMounts.";
          type = (types.nullOr types.bool);
        };
        "secretRef" = mkOption {
          description = "secretRef specifies the secret to use for obtaining the StorageOS API\ncredentials.  If not specified, default values will be attempted.";
          type = (
            types.nullOr (
              submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesStorageosSecretRef"
            )
          );
        };
        "volumeName" = mkOption {
          description = "volumeName is the human-readable name of the StorageOS volume.  Volume\nnames are only unique within a namespace.";
          type = (types.nullOr types.str);
        };
        "volumeNamespace" = mkOption {
          description = "volumeNamespace specifies the scope of the volume within StorageOS.  If no\nnamespace is specified then the Pod's namespace will be used.  This allows the\nKubernetes name scoping to be mirrored within StorageOS for tighter integration.\nSet VolumeName to any name to override the default behaviour.\nSet to \"default\" if you are not using namespaces within StorageOS.\nNamespaces that do not pre-exist within StorageOS will be created.";
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesStorageosSecretRef" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecHooksPreVolumesVsphereVolume" = {

      options = {
        "fsType" = mkOption {
          description = "fsType is filesystem type to mount.\nMust be a filesystem type supported by the host operating system.\nEx. \"ext4\", \"xfs\", \"ntfs\". Implicitly inferred to be \"ext4\" if unspecified.";
          type = (types.nullOr types.str);
        };
        "storagePolicyID" = mkOption {
          description = "storagePolicyID is the storage Policy Based Management (SPBM) profile ID associated with the StoragePolicyName.";
          type = (types.nullOr types.str);
        };
        "storagePolicyName" = mkOption {
          description = "storagePolicyName is the storage Policy Based Management (SPBM) profile name.";
          type = (types.nullOr types.str);
        };
        "volumePath" = mkOption {
          description = "volumePath is the path that identifies vSphere volume vmdk";
          type = types.str;
        };
      };

      config = {
        "fsType" = mkOverride 1002 null;
        "storagePolicyID" = mkOverride 1002 null;
        "storagePolicyName" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecMaintenance" = {

      options = {
        "windows" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecMaintenanceWindows")
            )
          );
        };
      };

      config = {
        "windows" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecMaintenanceWindows" = {

      options = {
        "duration" = mkOption {
          description = "How long the window stays open (e.g., \"4h\", \"2h30m\")";
          type = types.str;
        };
        "start" = mkOption {
          description = "Cron expression (5-field): minute hour day-of-month month day-of-week";
          type = (types.withMinLength 9 types.str);
        };
        "timezone" = mkOption {
          description = "IANA timezone (e.g., \"UTC\", \"Europe/Paris\")";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "timezone" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecNodeSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecNodeSelectorMatchExpressions"
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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecNodeSelectorMatchExpressions" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecPolicy" = {

      options = {
        "debug" = mkOption {
          description = "Debug enables debug mode for the upgrade";
          type = (types.nullOr types.bool);
        };
        "drainTimeout" = mkOption {
          description = "DrainTimeout bounds talosctl's own node drain (talosctl 1.13+); the upgrade\nfails without rebooting when the drain exceeds it. Unset keeps talosctl's\ndefault. Ignored when talosctl's drain is disabled.";
          type = (types.nullOr types.str);
        };
        "force" = mkOption {
          description = "Force the upgrade (skip checks on etcd health and members)";
          type = (types.nullOr types.bool);
        };
        "nodrain" = mkOption {
          description = "NoDrain disables drain for the upgrade.";
          type = (types.nullOr types.bool);
        };
        "placement" = mkOption {
          description = "Placement controls how strictly upgrade jobs avoid the target node\nhard: required avoidance, degrades to preferred on single-node clusters\nsoft: preferred avoidance (job prefers to avoid but can run on target node)";
          type = (
            types.nullOr (
              types.enum [
                "hard"
                "soft"
              ]
            )
          );
        };
        "priorityClassName" = mkOption {
          description = "PriorityClassName for the upgrade job pod; set a preempting class to displace lower-priority pods under resource pressure.";
          type = (types.nullOr types.str);
        };
        "rebootMode" = mkOption {
          description = "RebootMode select the reboot mode during upgrade";
          type = (
            types.nullOr (
              types.enum [
                "default"
                "powercycle"
              ]
            )
          );
        };
        "stage" = mkOption {
          description = "Stage the upgrade to perform it after a reboot";
          type = (types.nullOr types.bool);
        };
        "timeout" = mkOption {
          description = "Timeout for the per-node talosctl upgrade command";
          type = (types.nullOr types.str);
        };
        "waitForVolumeDetach" = mkOption {
          description = "WaitForVolumeDetach makes tuppr drain the node and wait for its CSI volumes to\ndetach before the Talos reboot (upgrading with Talos drain disabled), avoiding a\nMulti-Attach error when a fast reboot orphans a mount. No-op on single-node.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "debug" = mkOverride 1002 null;
        "drainTimeout" = mkOverride 1002 null;
        "force" = mkOverride 1002 null;
        "nodrain" = mkOverride 1002 null;
        "placement" = mkOverride 1002 null;
        "priorityClassName" = mkOverride 1002 null;
        "rebootMode" = mkOverride 1002 null;
        "stage" = mkOverride 1002 null;
        "timeout" = mkOverride 1002 null;
        "waitForVolumeDetach" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecSilences" = {

      options = {
        "matchers" = mkOption {
          description = "Matchers select the alerts this silence covers. Alertmanager ANDs the\nmatchers of one silence; use a regex value to cover alternatives, or\nadditional silences for independent scopes.";
          type = (
            coerceAttrsOfSubmodulesToListByKey
              "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecSilencesMatchers"
              "name"
              [ ]
          );
          apply = attrsToList;
        };
        "maxDuration" = mkOption {
          description = "MaxDuration hard-caps how long a continuous silence hold keeps being\nextended; a run still holding this silence beyond it alerts again. The\nbudget re-arms when the hold is released (run parked or finished).";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "maxDuration" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecSilencesMatchers" = {

      options = {
        "matchType" = mkOption {
          description = "MatchType is the match operator: = (equals), != , =~ (regex), !~.";
          type = (
            types.nullOr (
              types.enum [
                "="
                "!="
                "=~"
                "!~"
              ]
            )
          );
        };
        "name" = mkOption {
          description = "Name of the alert label to match.";
          type = (types.withMinLength 1 types.str);
        };
        "value" = mkOption {
          description = "Value the label is matched against.";
          type = (types.withMinLength 1 types.str);
        };
      };

      config = {
        "matchType" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecTalos" = {

      options = {
        "prePull" = mkOption {
          description = "PrePull pulls each node's resolved installer image at the start of a run,\nbefore the first node is cordoned, so an unreachable registry or a bad\nschematic/tag parks the run before any disruption. Nodes running Talos\nolder than v1.13 (no ImageService API) are skipped. Disable for airgapped\nclusters that seed images out of band.";
          type = (types.nullOr types.bool);
        };
        "version" = mkOption {
          description = "Version is the target Talos version to upgrade to (e.g., \"v1.11.0\")";
          type = types.str;
        };
      };

      config = {
        "prePull" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecTalosctl" = {

      options = {
        "image" = mkOption {
          description = "Image specifies the talosctl container image";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecTalosctlImage")
          );
        };
      };

      config = {
        "image" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeSpecTalosctlImage" = {

      options = {
        "pullPolicy" = mkOption {
          description = "PullPolicy describes a policy for if/when to pull a container image";
          type = (
            types.nullOr (
              types.enum [
                "Always"
                "Never"
                "IfNotPresent"
              ]
            )
          );
        };
        "repository" = mkOption {
          description = "Repository is the talosctl container image repository";
          type = (types.nullOr types.str);
        };
        "tag" = mkOption {
          description = "Tag is the talosctl container image tag\nIf not specified, defaults to the target version";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "pullPolicy" = mkOverride 1002 null;
        "repository" = mkOverride 1002 null;
        "tag" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatus" = {

      options = {
        "alertSilenceIDs" = mkOption {
          description = "AlertSilenceIDs are the Alertmanager silences this run holds open, indexed\nlike spec.silences (an empty entry is a silence not yet created). Persisted\nso the leases are re-adopted across controller restarts and expired when\nthe run leaves its active phases.";
          type = (types.nullOr (types.listOf types.str));
        };
        "alertSilencesSince" = mkOption {
          description = "AlertSilencesSince is when the current silence hold began; each entry's\nmaxDuration caps extension relative to it. Cleared when the hold is\nreleased, so a resumed run gets a fresh budget.";
          type = (types.nullOr types.str);
        };
        "completedAt" = mkOption {
          description = "CompletedAt is the time the upgrade reached a terminal phase";
          type = (types.nullOr types.str);
        };
        "completedNodes" = mkOption {
          description = "CompletedNodes are nodes that have been successfully upgraded";
          type = (types.nullOr (types.listOf types.str));
        };
        "completionCycles" = mkOption {
          description = "CompletionCycles counts Completed→Pending re-entries: a completed run\nre-opened because a matching node still needs the target version. Bounds\nrestart loops; reset by spec changes and the reset annotation.";
          type = (types.nullOr types.int);
        };
        "conditions" = mkOption {
          description = "Conditions report the upgrade's \"Progressing\" and \"Ready\" status.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusConditions")
            )
          );
        };
        "currentNode" = mkOption {
          description = "CurrentNode is the node currently being upgraded (first node in batch for backwards compatibility)";
          type = (types.nullOr types.str);
        };
        "currentNodes" = mkOption {
          description = "CurrentNodes is the list of nodes currently being upgraded in the active batch";
          type = (types.nullOr (types.listOf types.str));
        };
        "failedNodes" = mkOption {
          description = "FailedNodes are nodes that failed to upgrade";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusFailedNodes")
            )
          );
        };
        "history" = mkOption {
          description = "History records past version transitions on this CR, newest first";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusHistory")
            )
          );
        };
        "lastUpdated" = mkOption {
          description = "LastUpdated timestamp of last status update";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "Message provides details about the current state";
          type = (types.nullOr types.str);
        };
        "nextMaintenanceWindow" = mkOption {
          description = "NextMaintenanceWindow reflect the next time a maintenance can happen";
          type = (types.nullOr types.str);
        };
        "observedGeneration" = mkOption {
          description = "ObservedGeneration reflects the generation of the most recently observed spec";
          type = (types.nullOr types.int);
        };
        "phase" = mkOption {
          description = "Phase represents the current phase of the upgrade";
          type = (
            types.nullOr (
              types.enum [
                "Pending"
                "HealthChecking"
                "PreHook"
                "Draining"
                "Upgrading"
                "Rebooting"
                "PostHook"
                "Completed"
                "Failed"
                "MaintenanceWindow"
              ]
            )
          );
        };
        "postHookIndex" = mkOption {
          description = "PostHookIndex is the index of the next post-hook to run.";
          type = (types.nullOr types.int);
        };
        "preHookFailed" = mkOption {
          description = "PreHookFailed records that a pre-hook failed during this run, so the\nterminal phase ends up Failed even after post-hooks (cleanup) succeed.";
          type = (types.nullOr types.bool);
        };
        "preHookIndex" = mkOption {
          description = "PreHookIndex is the index of the next pre-hook to run.\nEquals len(spec.hooks.pre) once all pre-hooks are done.";
          type = (types.nullOr types.int);
        };
        "prePullFailure" = mkOption {
          description = "PrePullFailure tracks the current streak of consecutive failed pre-pull\ncycles, so a crash-looping pre-pull stays visible in status instead of\nbeing overwritten by the next cycle's Pre-pulling message. Drives the\nretry backoff; cleared once a pass completes without a failure.";
          type = (
            types.nullOr (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusPrePullFailure")
          );
        };
        "prePulledNodes" = mkOption {
          description = "PrePulledNodes records the installer image pre-pulled on each node\nduring this run (or noted as skipped because the node's Talos version\npredates the ImageService API), so pulls are not repeated on every\nreconcile. A record is keyed by the resolved ref and the Node UID: a\nnode that becomes eligible mid-run, is recreated under the same name,\nor whose resolved image changes (annotations, machine config), is\npre-pulled before its next batch.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusPrePulledNodes")
            )
          );
        };
        "rebootingNodes" = mkOption {
          description = "RebootingNodes tracks nodes whose upgrade job finished but whose\npost-reboot readiness has not been verified yet. Persisted in status so\nthe wait survives upgrade Job garbage collection; a node that never\ncomes back is marked failed once its deadline passes.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusRebootingNodes")
            )
          );
        };
        "startedAt" = mkOption {
          description = "StartedAt is the time the current upgrade run began";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "alertSilenceIDs" = mkOverride 1002 null;
        "alertSilencesSince" = mkOverride 1002 null;
        "completedAt" = mkOverride 1002 null;
        "completedNodes" = mkOverride 1002 null;
        "completionCycles" = mkOverride 1002 null;
        "conditions" = mkOverride 1002 null;
        "currentNode" = mkOverride 1002 null;
        "currentNodes" = mkOverride 1002 null;
        "failedNodes" = mkOverride 1002 null;
        "history" = mkOverride 1002 null;
        "lastUpdated" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "nextMaintenanceWindow" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
        "phase" = mkOverride 1002 null;
        "postHookIndex" = mkOverride 1002 null;
        "preHookFailed" = mkOverride 1002 null;
        "preHookIndex" = mkOverride 1002 null;
        "prePullFailure" = mkOverride 1002 null;
        "prePulledNodes" = mkOverride 1002 null;
        "rebootingNodes" = mkOverride 1002 null;
        "startedAt" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusConditions" = {

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
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusFailedNodes" = {

      options = {
        "jobName" = mkOption {
          description = "JobName is the name of the job handling this node's upgrade";
          type = (types.nullOr types.str);
        };
        "lastError" = mkOption {
          description = "LastError contains the last error message";
          type = (types.nullOr types.str);
        };
        "nodeName" = mkOption {
          description = "NodeName is the name of the node";
          type = types.str;
        };
        "retries" = mkOption {
          description = "Retries is the number of times upgrade was attempted";
          type = (types.nullOr (types.withMinimum 0 types.int));
        };
      };

      config = {
        "jobName" = mkOverride 1002 null;
        "lastError" = mkOverride 1002 null;
        "retries" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusHistory" = {

      options = {
        "completedAt" = mkOption {
          description = "CompletedAt is when the run reached its terminal phase";
          type = types.str;
        };
        "completedNodes" = mkOption {
          description = "CompletedNodes are the nodes successfully upgraded during the run";
          type = (types.nullOr (types.listOf types.str));
        };
        "failedNodes" = mkOption {
          description = "FailedNodes are the nodes that failed during the run";
          type = (types.nullOr (types.listOf types.str));
        };
        "phase" = mkOption {
          description = "Phase is the terminal phase reached (Completed or Failed)";
          type = (
            types.enum [
              "Pending"
              "HealthChecking"
              "PreHook"
              "Draining"
              "Upgrading"
              "Rebooting"
              "PostHook"
              "Completed"
              "Failed"
              "MaintenanceWindow"
            ]
          );
        };
        "startedAt" = mkOption {
          description = "StartedAt is when the run began";
          type = types.str;
        };
        "toVersion" = mkOption {
          description = "ToVersion is the spec-target Talos version at the time of completion";
          type = types.str;
        };
      };

      config = {
        "completedNodes" = mkOverride 1002 null;
        "failedNodes" = mkOverride 1002 null;
      };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusPrePullFailure" = {

      options = {
        "attempts" = mkOption {
          description = "Attempts is the number of consecutive pre-pull cycles that have failed.";
          type = types.int;
        };
        "lastError" = mkOption {
          description = "LastError is the failure from the most recent cycle.";
          type = types.str;
        };
      };

      config = { };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusPrePulledNodes" = {

      options = {
        "image" = mkOption {
          description = "Image is the installer ref that was resolved for the node when it was\npulled (or skipped as unsupported). A different resolved ref\ninvalidates the record.";
          type = types.str;
        };
        "nodeName" = mkOption {
          description = "NodeName is the name of the node.";
          type = types.str;
        };
        "nodeUID" = mkOption {
          description = "NodeUID is the UID of the Node object the pull was performed against.\nA node recreated under the same name (new UID) invalidates the record:\nits image store starts empty.";
          type = types.str;
        };
      };

      config = { };

    };
    "tuppr.home-operations.com.v1alpha1.TalosUpgradeStatusRebootingNodes" = {

      options = {
        "deadline" = mkOption {
          description = "Deadline is when the reboot wait expires and the node is marked failed";
          type = types.str;
        };
        "nodeName" = mkOption {
          description = "NodeName is the name of the node";
          type = types.str;
        };
      };

      config = { };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "tuppr.home-operations.com"."v1alpha1"."KubernetesUpgrade" = mkOption {
        description = "KubernetesUpgrade is the Schema for the kubernetesupgrades API";
        type = (
          types.attrsOf (
            submoduleForDefinition "tuppr.home-operations.com.v1alpha1.KubernetesUpgrade" "kubernetesupgrades"
              "KubernetesUpgrade"
              "tuppr.home-operations.com"
              "v1alpha1"
          )
        );
        default = { };
      };
      "tuppr.home-operations.com"."v1alpha1"."TalosUpgrade" = mkOption {
        description = "TalosUpgrade is the Schema for the talosupgrades API";
        type = (
          types.attrsOf (
            submoduleForDefinition "tuppr.home-operations.com.v1alpha1.TalosUpgrade" "talosupgrades"
              "TalosUpgrade"
              "tuppr.home-operations.com"
              "v1alpha1"
          )
        );
        default = { };
      };

    }
    // {
      "kubernetesUpgrades" = mkOption {
        description = "KubernetesUpgrade is the Schema for the kubernetesupgrades API";
        type = (
          types.attrsOf (
            submoduleForDefinition "tuppr.home-operations.com.v1alpha1.KubernetesUpgrade" "kubernetesupgrades"
              "KubernetesUpgrade"
              "tuppr.home-operations.com"
              "v1alpha1"
          )
        );
        default = { };
      };
      "talosUpgrades" = mkOption {
        description = "TalosUpgrade is the Schema for the talosupgrades API";
        type = (
          types.attrsOf (
            submoduleForDefinition "tuppr.home-operations.com.v1alpha1.TalosUpgrade" "talosupgrades"
              "TalosUpgrade"
              "tuppr.home-operations.com"
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
        name = "kubernetesupgrades";
        group = "tuppr.home-operations.com";
        version = "v1alpha1";
        kind = "KubernetesUpgrade";
        attrName = "kubernetesUpgrades";
      }
      {
        name = "talosupgrades";
        group = "tuppr.home-operations.com";
        version = "v1alpha1";
        kind = "TalosUpgrade";
        attrName = "talosUpgrades";
      }
    ];

    resources = {
      "tuppr.home-operations.com"."v1alpha1"."KubernetesUpgrade" =
        mkAliasDefinitions
          options.resources."kubernetesUpgrades";
      "tuppr.home-operations.com"."v1alpha1"."TalosUpgrade" =
        mkAliasDefinitions
          options.resources."talosUpgrades";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [ ];
  };
}
