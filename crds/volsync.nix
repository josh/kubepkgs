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
    "volsync.backube.v1alpha1.ReplicationDestination" = {

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
          description = "spec is the desired state of the ReplicationDestination, including the\nreplication method to use and its configuration.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpec"));
        };
        "status" = mkOption {
          description = "status is the observed state of the ReplicationDestination as determined\nby the controller.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationStatus"));
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpec" = {

      options = {
        "external" = mkOption {
          description = "external defines the configuration when using an external replication\nprovider.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecExternal"));
        };
        "paused" = mkOption {
          description = "paused can be used to temporarily stop replication. Defaults to \"false\".";
          type = (types.nullOr types.bool);
        };
        "rclone" = mkOption {
          description = "rclone defines the configuration when using Rclone-based replication.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRclone"));
        };
        "restic" = mkOption {
          description = "restic defines the configuration when using Restic-based replication.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRestic"));
        };
        "rsync" = mkOption {
          description = "rsync defines the configuration when using Rsync-based replication.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsync"));
        };
        "rsyncTLS" = mkOption {
          description = "rsyncTLS defines the configuration when using Rsync-based replication over TLS.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLS"));
        };
        "trigger" = mkOption {
          description = "trigger determines if/when the destination should attempt to synchronize\ndata with the source.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecTrigger"));
        };
      };

      config = {
        "external" = mkOverride 1002 null;
        "paused" = mkOverride 1002 null;
        "rclone" = mkOverride 1002 null;
        "restic" = mkOverride 1002 null;
        "rsync" = mkOverride 1002 null;
        "rsyncTLS" = mkOverride 1002 null;
        "trigger" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecExternal" = {

      options = {
        "parameters" = mkOption {
          description = "parameters are provider-specific key/value configuration parameters. For\nmore information, please see the documentation of the specific\nreplication provider being used.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "provider" = mkOption {
          description = "provider is the name of the external replication provider. The name\nshould be of the form: domain.com/provider.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "parameters" = mkOverride 1002 null;
        "provider" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRclone" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes specifies the access modes for the destination volume.";
          type = (types.nullOr (types.listOf types.str));
        };
        "capacity" = mkOption {
          description = "capacity is the size of the destination volume to create.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "cleanupTempPVC" = mkOption {
          description = "Set this to true to delete the temp destination PVC (dynamically provisioned\nby VolSync) at the end of each successful ReplicationDestination sync iteration.\nIf destinationPVC is set, this will have no effect, VolSync will only\ncleanup temp PVCs that it deployed.\nNote that if this is set to true, every sync this ReplicationDestination\nmakes will re-provision a new temp destination PVC and all data\nwill need to be sent again during the sync.\nDynamically provisioned destination PVCs will always be deleted if the\nowning ReplicationDestination is removed, even if this setting is false.\nThe default is false.";
          type = (types.nullOr types.bool);
        };
        "copyMethod" = mkOption {
          description = "copyMethod describes how a point-in-time (PiT) image of the destination\nvolume should be created.";
          type = (
            types.nullOr (
              types.enum [
                "Direct"
                "None"
                "Clone"
                "Snapshot"
              ]
            )
          );
        };
        "customCA" = mkOption {
          description = "customCA is a custom CA that will be used to verify the remote";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneCustomCA")
          );
        };
        "destinationPVC" = mkOption {
          description = "destinationPVC is a PVC to use as the transfer destination instead of\nautomatically provisioning one. Either this field or both capacity and\naccessModes must be specified.";
          type = (types.nullOr types.str);
        };
        "moverAffinity" = mkOption {
          description = "MoverAffinity allows specifying the PodAffinity that will be used by the data mover";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinity")
          );
        };
        "moverPodLabels" = mkOption {
          description = "Labels that should be added to data mover pods\nThese will be in addition to any labels that VolSync may add";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "moverResources" = mkOption {
          description = "Resources represents compute resources required by the data mover container.\nImmutable.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/\nThis should only be used by advanced users as this can result in a mover\npod being unschedulable or crashing due to limited resources.";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverResources")
          );
        };
        "moverSecurityContext" = mkOption {
          description = "MoverSecurityContext allows specifying the PodSecurityContext that will\nbe used by the data mover";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContext"
            )
          );
        };
        "moverServiceAccount" = mkOption {
          description = "MoverServiceAccount allows specifying the name of the service account\nthat will be used by the data mover. This should only be used by advanced\nusers who want to override the service account normally used by the mover.\nThe service account needs to exist in the same namespace as this CR.";
          type = (types.nullOr types.str);
        };
        "moverVolumes" = mkOption {
          description = "MoverVolumes are PVCs or Secrets that should additionally be mounted to the mover job pod.\nThis should only be used by advanced users.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumes")
            )
          );
        };
        "rcloneConfig" = mkOption {
          description = "RcloneConfig is the rclone secret name";
          type = (types.nullOr types.str);
        };
        "rcloneConfigSection" = mkOption {
          description = "RcloneConfigSection is the section in rclone_config file to use for the current job.";
          type = (types.nullOr types.str);
        };
        "rcloneDestPath" = mkOption {
          description = "RcloneDestPath is the remote path to sync to.";
          type = (types.nullOr types.str);
        };
        "storageClassName" = mkOption {
          description = "storageClassName can be used to specify the StorageClass of the\ndestination volume. If not set, the default StorageClass will be used.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotClassName" = mkOption {
          description = "volumeSnapshotClassName can be used to specify the VSC to be used if\ncopyMethod is Snapshot. If not set, the default VSC is used.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "cleanupTempPVC" = mkOverride 1002 null;
        "copyMethod" = mkOverride 1002 null;
        "customCA" = mkOverride 1002 null;
        "destinationPVC" = mkOverride 1002 null;
        "moverAffinity" = mkOverride 1002 null;
        "moverPodLabels" = mkOverride 1002 null;
        "moverResources" = mkOverride 1002 null;
        "moverSecurityContext" = mkOverride 1002 null;
        "moverServiceAccount" = mkOverride 1002 null;
        "moverVolumes" = mkOverride 1002 null;
        "rcloneConfig" = mkOverride 1002 null;
        "rcloneConfigSection" = mkOverride 1002 null;
        "rcloneDestPath" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "volumeSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneCustomCA" = {

      options = {
        "configMapName" = mkOption {
          description = "The name of a ConfigMap that contains the custom CA certificate\nIf ConfigMapName is used then SecretName should not be set";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "The key within the Secret or ConfigMap containing the CA certificate";
          type = (types.nullOr types.str);
        };
        "secretName" = mkOption {
          description = "The name of a Secret that contains the custom CA certificate\nIf SecretName is used then ConfigMapName should not be set";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "configMapName" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinity"
            )
          );
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinity"
            )
          );
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinity"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node matches the corresponding matchExpressions; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to an update), the system\nmay or may not try to eventually evict the pod from its node.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A node selector term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe anti-affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling anti-affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and subtracting\n\"weight\" from the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the anti-affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverResourcesClaims"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverResourcesClaims" = {

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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContext" = {

      options = {
        "appArmorProfile" = mkOption {
          description = "appArmorProfile is the AppArmor options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContextAppArmorProfile"
            )
          );
        };
        "fsGroup" = mkOption {
          description = "A special supplemental group that applies to all containers in a pod.\nSome volume types allow the Kubelet to change the ownership of that volume\nto be owned by the pod:\n\n1. The owning GID will be the FSGroup\n2. The setgid bit is set (new files created in the volume will be owned by FSGroup)\n3. The permission bits are OR'd with rw-rw----\n\nIf unset, the Kubelet will not modify the ownership and permissions of any volume.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "fsGroupChangePolicy" = mkOption {
          description = "fsGroupChangePolicy defines behavior of changing ownership and permission of the volume\nbefore being exposed inside Pod. This field will only apply to\nvolume types which support fsGroup based ownership(and permissions).\nIt will have no effect on ephemeral volume types such as: secret, configmaps\nand emptydir.\nValid values are \"OnRootMismatch\" and \"Always\". If not specified, \"Always\" is used.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "runAsGroup" = mkOption {
          description = "The GID to run the entrypoint of the container process.\nUses runtime default if unset.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "Indicates that the container must run as a non-root user.\nIf true, the Kubelet will validate the image at runtime to ensure that it\ndoes not run as UID 0 (root) and fail to start the container if it does.\nIf unset or false, no such validation will be performed.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "The UID to run the entrypoint of the container process.\nDefaults to user specified in image metadata if unspecified.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "seLinuxChangePolicy" = mkOption {
          description = "seLinuxChangePolicy defines how the container's SELinux label is applied to all volumes used by the Pod.\nIt has no effect on nodes that do not support SELinux or to volumes does not support SELinux.\nValid values are \"MountOption\" and \"Recursive\".\n\n\"Recursive\" means relabeling of all files on all Pod volumes by the container runtime.\nThis may be slow for large volumes, but allows mixing privileged and unprivileged Pods sharing the same volume on the same node.\n\n\"MountOption\" mounts all eligible Pod volumes with `-o context` mount option.\nThis requires all Pods that share the same volume to use the same SELinux label.\nIt is not possible to share the same volume among privileged and unprivileged Pods.\nEligible volumes are in-tree FibreChannel and iSCSI volumes, and all CSI volumes\nwhose CSI driver announces SELinux support by setting spec.seLinuxMount: true in their\nCSIDriver instance. Other volumes are always re-labelled recursively.\n\"MountOption\" value is allowed only when SELinuxMount feature gate is enabled.\n\nIf not specified and SELinuxMount feature gate is enabled, \"MountOption\" is used.\nIf not specified and SELinuxMount feature gate is disabled, \"MountOption\" is used for ReadWriteOncePod volumes\nand \"Recursive\" for all other volumes.\n\nThis field affects only Pods that have SELinux label set, either in PodSecurityContext or in SecurityContext of all containers.\n\nAll Pods that use the same volume should use the same seLinuxChangePolicy, otherwise some pods can get stuck in ContainerCreating state.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "seLinuxOptions" = mkOption {
          description = "The SELinux context to be applied to all containers.\nIf unspecified, the container runtime will allocate a random SELinux context for each\ncontainer.  May also be set in SecurityContext.  If set in\nboth SecurityContext and PodSecurityContext, the value specified in SecurityContext\ntakes precedence for that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContextSeLinuxOptions"
            )
          );
        };
        "seccompProfile" = mkOption {
          description = "The seccomp options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContextSeccompProfile"
            )
          );
        };
        "supplementalGroups" = mkOption {
          description = "A list of groups applied to the first process run in each container, in\naddition to the container's primary GID and fsGroup (if specified).  If\nthe SupplementalGroupsPolicy feature is enabled, the\nsupplementalGroupsPolicy field determines whether these are in addition\nto or instead of any group memberships defined in the container image.\nIf unspecified, no additional groups are added, though group memberships\ndefined in the container image may still be used, depending on the\nsupplementalGroupsPolicy field.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (types.listOf types.int));
        };
        "supplementalGroupsPolicy" = mkOption {
          description = "Defines how supplemental groups of the first container processes are calculated.\nValid values are \"Merge\" and \"Strict\". If not specified, \"Merge\" is used.\n(Alpha) Using the field requires the SupplementalGroupsPolicy feature gate to be enabled\nand the container runtime must implement support for this feature.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "sysctls" = mkOption {
          description = "Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported\nsysctls (by the container runtime) might fail to launch.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContextSysctls"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "windowsOptions" = mkOption {
          description = "The Windows specific settings applied to all containers.\nIf unspecified, the options within a container's SecurityContext will be used.\nIf set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.\nNote that this field cannot be set when spec.os.name is linux.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContextWindowsOptions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContextAppArmorProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile loaded on the node that should be used.\nThe profile must be preconfigured on the node to work.\nMust match the loaded name of the profile.\nMust be set if and only if type is \"Localhost\".";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of AppArmor profile will be applied.\nValid options are:\n  Localhost - a profile pre-loaded on the node.\n  RuntimeDefault - the container runtime's default profile.\n  Unconfined - no AppArmor enforcement.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContextSeLinuxOptions" = {

      options = {
        "level" = mkOption {
          description = "Level is SELinux level label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "Role is a SELinux role label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type is a SELinux type label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "User is a SELinux user label that applies to the container.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContextSeccompProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile defined in a file on the node should be used.\nThe profile must be preconfigured on the node to work.\nMust be a descending path, relative to the kubelet's configured seccomp profile location.\nMust be set if type is \"Localhost\". Must NOT be set for any other type.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of seccomp profile will be applied.\nValid options are:\n\nLocalhost - a profile defined in a file on the node should be used.\nRuntimeDefault - the container runtime default profile should be used.\nUnconfined - no profile should be applied.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContextSysctls" = {

      options = {
        "name" = mkOption {
          description = "Name of a property to set";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value of a property to set";
          type = types.str;
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverSecurityContextWindowsOptions" = {

      options = {
        "gmsaCredentialSpec" = mkOption {
          description = "GMSACredentialSpec is where the GMSA admission webhook\n(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the\nGMSA credential spec named by the GMSACredentialSpecName field.";
          type = (types.nullOr types.str);
        };
        "gmsaCredentialSpecName" = mkOption {
          description = "GMSACredentialSpecName is the name of the GMSA credential spec to use.";
          type = (types.nullOr types.str);
        };
        "hostProcess" = mkOption {
          description = "HostProcess determines if a container should be run as a 'Host Process' container.\nAll of a Pod's containers must have the same effective HostProcess value\n(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).\nIn addition, if HostProcess is true then HostNetwork must also be set to true.";
          type = (types.nullOr types.bool);
        };
        "runAsUserName" = mkOption {
          description = "The UserName in Windows to run the entrypoint of the container process.\nDefaults to the user specified in image metadata if unspecified.\nMay also be set in PodSecurityContext. If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumes" = {

      options = {
        "mountPath" = mkOption {
          description = "Path to give the volume when mounting under /mnt in the mover job pod.\nFor example if mountPath is 'my-pvc' then this moverVolume will be mounted in the mover pod\nat /mnt/my-pvc";
          type = types.str;
        };
        "volumeSource" = mkOption {
          description = "volumeSource represents the secret or PersistentVolumeClaim that should be mounted to the mover pod.";
          type = (
            submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumesVolumeSource"
          );
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumesVolumeSource" = {

      options = {
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host that shares a pod's lifetime\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumesVolumeSourceNfs"
            )
          );
        };
        "persistentVolumeClaim" = mkOption {
          description = "persistentVolumeClaimVolumeSource represents a reference to a\nPersistentVolumeClaim in the same namespace.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims\nnolint:lll";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumesVolumeSourcePersistentVolumeClaim"
            )
          );
        };
        "secret" = mkOption {
          description = "secret represents a secret that should populate this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumesVolumeSourceSecret"
            )
          );
        };
      };

      config = {
        "nfs" = mkOverride 1002 null;
        "persistentVolumeClaim" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumesVolumeSourceNfs" = {

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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumesVolumeSourcePersistentVolumeClaim" =
      {

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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumesVolumeSourceSecret" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is Optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values\nfor mode bits. Defaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items If unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumesVolumeSourceSecretItems"
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
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRcloneMoverVolumesVolumeSourceSecretItems" = {

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
      };

      config = {
        "mode" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRestic" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes specifies the access modes for the destination volume.";
          type = (types.nullOr (types.listOf types.str));
        };
        "cacheAccessModes" = mkOption {
          description = "accessModes can be used to set the accessModes of restic metadata cache volume";
          type = (types.nullOr (types.listOf types.str));
        };
        "cacheCapacity" = mkOption {
          description = "cacheCapacity can be used to set the size of the restic metadata cache volume";
          type = (types.nullOr (types.either types.int types.str));
        };
        "cacheStorageClassName" = mkOption {
          description = "cacheStorageClassName can be used to set the StorageClass of the restic\nmetadata cache volume";
          type = (types.nullOr types.str);
        };
        "capacity" = mkOption {
          description = "capacity is the size of the destination volume to create.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "cleanupCachePVC" = mkOption {
          description = "Set this to true to delete the restic cache PVC (dynamically provisioned\nby VolSync) at the end of each successful ReplicationDestination sync iteration.\nCache PVCs will always be deleted if the owning ReplicationDestination is\nremoved, even if this setting is false.\nThe default is false.";
          type = (types.nullOr types.bool);
        };
        "cleanupTempPVC" = mkOption {
          description = "Set this to true to delete the temp destination PVC (dynamically provisioned\nby VolSync) at the end of each successful ReplicationDestination sync iteration.\nIf destinationPVC is set, this will have no effect, VolSync will only\ncleanup temp PVCs that it deployed.\nNote that if this is set to true, every sync this ReplicationDestination\nmakes will re-provision a new temp destination PVC and all data\nwill need to be sent again during the sync.\nDynamically provisioned destination PVCs will always be deleted if the\nowning ReplicationDestination is removed, even if this setting is false.\nThe default is false.";
          type = (types.nullOr types.bool);
        };
        "copyMethod" = mkOption {
          description = "copyMethod describes how a point-in-time (PiT) image of the destination\nvolume should be created.";
          type = (
            types.nullOr (
              types.enum [
                "Direct"
                "None"
                "Clone"
                "Snapshot"
              ]
            )
          );
        };
        "customCA" = mkOption {
          description = "customCA is a custom CA that will be used to verify the remote";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticCustomCA")
          );
        };
        "destinationPVC" = mkOption {
          description = "destinationPVC is a PVC to use as the transfer destination instead of\nautomatically provisioning one. Either this field or both capacity and\naccessModes must be specified.";
          type = (types.nullOr types.str);
        };
        "enableFileDeletion" = mkOption {
          description = "enableFileDeletion will pass the --delete flag to the restic restore command.\nThis will remove files and directories in the pvc that do not exist in the snapshot being restored.\nDefaults to false.";
          type = (types.nullOr types.bool);
        };
        "moverAffinity" = mkOption {
          description = "MoverAffinity allows specifying the PodAffinity that will be used by the data mover";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinity")
          );
        };
        "moverPodLabels" = mkOption {
          description = "Labels that should be added to data mover pods\nThese will be in addition to any labels that VolSync may add";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "moverResources" = mkOption {
          description = "Resources represents compute resources required by the data mover container.\nImmutable.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/\nThis should only be used by advanced users as this can result in a mover\npod being unschedulable or crashing due to limited resources.";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverResources")
          );
        };
        "moverSecurityContext" = mkOption {
          description = "MoverSecurityContext allows specifying the PodSecurityContext that will\nbe used by the data mover";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContext"
            )
          );
        };
        "moverServiceAccount" = mkOption {
          description = "MoverServiceAccount allows specifying the name of the service account\nthat will be used by the data mover. This should only be used by advanced\nusers who want to override the service account normally used by the mover.\nThe service account needs to exist in the same namespace as this CR.";
          type = (types.nullOr types.str);
        };
        "moverVolumes" = mkOption {
          description = "MoverVolumes are PVCs or Secrets that should additionally be mounted to the mover job pod.\nThis should only be used by advanced users.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumes")
            )
          );
        };
        "previous" = mkOption {
          description = "Previous specifies the number of image to skip before selecting one to restore from";
          type = (types.nullOr types.int);
        };
        "repository" = mkOption {
          description = "Repository is the secret name containing repository info";
          type = (types.nullOr types.str);
        };
        "restoreAsOf" = mkOption {
          description = "RestoreAsOf refers to the backup that is most recent as of that time.";
          type = (types.nullOr types.str);
        };
        "storageClassName" = mkOption {
          description = "storageClassName can be used to specify the StorageClass of the\ndestination volume. If not set, the default StorageClass will be used.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotClassName" = mkOption {
          description = "volumeSnapshotClassName can be used to specify the VSC to be used if\ncopyMethod is Snapshot. If not set, the default VSC is used.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "cacheAccessModes" = mkOverride 1002 null;
        "cacheCapacity" = mkOverride 1002 null;
        "cacheStorageClassName" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "cleanupCachePVC" = mkOverride 1002 null;
        "cleanupTempPVC" = mkOverride 1002 null;
        "copyMethod" = mkOverride 1002 null;
        "customCA" = mkOverride 1002 null;
        "destinationPVC" = mkOverride 1002 null;
        "enableFileDeletion" = mkOverride 1002 null;
        "moverAffinity" = mkOverride 1002 null;
        "moverPodLabels" = mkOverride 1002 null;
        "moverResources" = mkOverride 1002 null;
        "moverSecurityContext" = mkOverride 1002 null;
        "moverServiceAccount" = mkOverride 1002 null;
        "moverVolumes" = mkOverride 1002 null;
        "previous" = mkOverride 1002 null;
        "repository" = mkOverride 1002 null;
        "restoreAsOf" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "volumeSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticCustomCA" = {

      options = {
        "configMapName" = mkOption {
          description = "The name of a ConfigMap that contains the custom CA certificate\nIf ConfigMapName is used then SecretName should not be set";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "The key within the Secret or ConfigMap containing the CA certificate";
          type = (types.nullOr types.str);
        };
        "secretName" = mkOption {
          description = "The name of a Secret that contains the custom CA certificate\nIf SecretName is used then ConfigMapName should not be set";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "configMapName" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinity"
            )
          );
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinity"
            )
          );
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinity"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node matches the corresponding matchExpressions; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to an update), the system\nmay or may not try to eventually evict the pod from its node.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A node selector term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe anti-affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling anti-affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and subtracting\n\"weight\" from the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the anti-affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverResourcesClaims"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverResourcesClaims" = {

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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContext" = {

      options = {
        "appArmorProfile" = mkOption {
          description = "appArmorProfile is the AppArmor options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContextAppArmorProfile"
            )
          );
        };
        "fsGroup" = mkOption {
          description = "A special supplemental group that applies to all containers in a pod.\nSome volume types allow the Kubelet to change the ownership of that volume\nto be owned by the pod:\n\n1. The owning GID will be the FSGroup\n2. The setgid bit is set (new files created in the volume will be owned by FSGroup)\n3. The permission bits are OR'd with rw-rw----\n\nIf unset, the Kubelet will not modify the ownership and permissions of any volume.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "fsGroupChangePolicy" = mkOption {
          description = "fsGroupChangePolicy defines behavior of changing ownership and permission of the volume\nbefore being exposed inside Pod. This field will only apply to\nvolume types which support fsGroup based ownership(and permissions).\nIt will have no effect on ephemeral volume types such as: secret, configmaps\nand emptydir.\nValid values are \"OnRootMismatch\" and \"Always\". If not specified, \"Always\" is used.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "runAsGroup" = mkOption {
          description = "The GID to run the entrypoint of the container process.\nUses runtime default if unset.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "Indicates that the container must run as a non-root user.\nIf true, the Kubelet will validate the image at runtime to ensure that it\ndoes not run as UID 0 (root) and fail to start the container if it does.\nIf unset or false, no such validation will be performed.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "The UID to run the entrypoint of the container process.\nDefaults to user specified in image metadata if unspecified.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "seLinuxChangePolicy" = mkOption {
          description = "seLinuxChangePolicy defines how the container's SELinux label is applied to all volumes used by the Pod.\nIt has no effect on nodes that do not support SELinux or to volumes does not support SELinux.\nValid values are \"MountOption\" and \"Recursive\".\n\n\"Recursive\" means relabeling of all files on all Pod volumes by the container runtime.\nThis may be slow for large volumes, but allows mixing privileged and unprivileged Pods sharing the same volume on the same node.\n\n\"MountOption\" mounts all eligible Pod volumes with `-o context` mount option.\nThis requires all Pods that share the same volume to use the same SELinux label.\nIt is not possible to share the same volume among privileged and unprivileged Pods.\nEligible volumes are in-tree FibreChannel and iSCSI volumes, and all CSI volumes\nwhose CSI driver announces SELinux support by setting spec.seLinuxMount: true in their\nCSIDriver instance. Other volumes are always re-labelled recursively.\n\"MountOption\" value is allowed only when SELinuxMount feature gate is enabled.\n\nIf not specified and SELinuxMount feature gate is enabled, \"MountOption\" is used.\nIf not specified and SELinuxMount feature gate is disabled, \"MountOption\" is used for ReadWriteOncePod volumes\nand \"Recursive\" for all other volumes.\n\nThis field affects only Pods that have SELinux label set, either in PodSecurityContext or in SecurityContext of all containers.\n\nAll Pods that use the same volume should use the same seLinuxChangePolicy, otherwise some pods can get stuck in ContainerCreating state.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "seLinuxOptions" = mkOption {
          description = "The SELinux context to be applied to all containers.\nIf unspecified, the container runtime will allocate a random SELinux context for each\ncontainer.  May also be set in SecurityContext.  If set in\nboth SecurityContext and PodSecurityContext, the value specified in SecurityContext\ntakes precedence for that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContextSeLinuxOptions"
            )
          );
        };
        "seccompProfile" = mkOption {
          description = "The seccomp options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContextSeccompProfile"
            )
          );
        };
        "supplementalGroups" = mkOption {
          description = "A list of groups applied to the first process run in each container, in\naddition to the container's primary GID and fsGroup (if specified).  If\nthe SupplementalGroupsPolicy feature is enabled, the\nsupplementalGroupsPolicy field determines whether these are in addition\nto or instead of any group memberships defined in the container image.\nIf unspecified, no additional groups are added, though group memberships\ndefined in the container image may still be used, depending on the\nsupplementalGroupsPolicy field.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (types.listOf types.int));
        };
        "supplementalGroupsPolicy" = mkOption {
          description = "Defines how supplemental groups of the first container processes are calculated.\nValid values are \"Merge\" and \"Strict\". If not specified, \"Merge\" is used.\n(Alpha) Using the field requires the SupplementalGroupsPolicy feature gate to be enabled\nand the container runtime must implement support for this feature.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "sysctls" = mkOption {
          description = "Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported\nsysctls (by the container runtime) might fail to launch.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContextSysctls"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "windowsOptions" = mkOption {
          description = "The Windows specific settings applied to all containers.\nIf unspecified, the options within a container's SecurityContext will be used.\nIf set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.\nNote that this field cannot be set when spec.os.name is linux.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContextWindowsOptions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContextAppArmorProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile loaded on the node that should be used.\nThe profile must be preconfigured on the node to work.\nMust match the loaded name of the profile.\nMust be set if and only if type is \"Localhost\".";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of AppArmor profile will be applied.\nValid options are:\n  Localhost - a profile pre-loaded on the node.\n  RuntimeDefault - the container runtime's default profile.\n  Unconfined - no AppArmor enforcement.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContextSeLinuxOptions" = {

      options = {
        "level" = mkOption {
          description = "Level is SELinux level label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "Role is a SELinux role label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type is a SELinux type label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "User is a SELinux user label that applies to the container.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContextSeccompProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile defined in a file on the node should be used.\nThe profile must be preconfigured on the node to work.\nMust be a descending path, relative to the kubelet's configured seccomp profile location.\nMust be set if type is \"Localhost\". Must NOT be set for any other type.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of seccomp profile will be applied.\nValid options are:\n\nLocalhost - a profile defined in a file on the node should be used.\nRuntimeDefault - the container runtime default profile should be used.\nUnconfined - no profile should be applied.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContextSysctls" = {

      options = {
        "name" = mkOption {
          description = "Name of a property to set";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value of a property to set";
          type = types.str;
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverSecurityContextWindowsOptions" = {

      options = {
        "gmsaCredentialSpec" = mkOption {
          description = "GMSACredentialSpec is where the GMSA admission webhook\n(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the\nGMSA credential spec named by the GMSACredentialSpecName field.";
          type = (types.nullOr types.str);
        };
        "gmsaCredentialSpecName" = mkOption {
          description = "GMSACredentialSpecName is the name of the GMSA credential spec to use.";
          type = (types.nullOr types.str);
        };
        "hostProcess" = mkOption {
          description = "HostProcess determines if a container should be run as a 'Host Process' container.\nAll of a Pod's containers must have the same effective HostProcess value\n(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).\nIn addition, if HostProcess is true then HostNetwork must also be set to true.";
          type = (types.nullOr types.bool);
        };
        "runAsUserName" = mkOption {
          description = "The UserName in Windows to run the entrypoint of the container process.\nDefaults to the user specified in image metadata if unspecified.\nMay also be set in PodSecurityContext. If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumes" = {

      options = {
        "mountPath" = mkOption {
          description = "Path to give the volume when mounting under /mnt in the mover job pod.\nFor example if mountPath is 'my-pvc' then this moverVolume will be mounted in the mover pod\nat /mnt/my-pvc";
          type = types.str;
        };
        "volumeSource" = mkOption {
          description = "volumeSource represents the secret or PersistentVolumeClaim that should be mounted to the mover pod.";
          type = (
            submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumesVolumeSource"
          );
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumesVolumeSource" = {

      options = {
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host that shares a pod's lifetime\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumesVolumeSourceNfs"
            )
          );
        };
        "persistentVolumeClaim" = mkOption {
          description = "persistentVolumeClaimVolumeSource represents a reference to a\nPersistentVolumeClaim in the same namespace.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims\nnolint:lll";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumesVolumeSourcePersistentVolumeClaim"
            )
          );
        };
        "secret" = mkOption {
          description = "secret represents a secret that should populate this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumesVolumeSourceSecret"
            )
          );
        };
      };

      config = {
        "nfs" = mkOverride 1002 null;
        "persistentVolumeClaim" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumesVolumeSourceNfs" = {

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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumesVolumeSourcePersistentVolumeClaim" =
      {

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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumesVolumeSourceSecret" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is Optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values\nfor mode bits. Defaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items If unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumesVolumeSourceSecretItems"
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
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecResticMoverVolumesVolumeSourceSecretItems" = {

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
      };

      config = {
        "mode" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsync" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes specifies the access modes for the destination volume.";
          type = (types.nullOr (types.listOf types.str));
        };
        "address" = mkOption {
          description = "address is the remote address to connect to for replication.";
          type = (types.nullOr types.str);
        };
        "capacity" = mkOption {
          description = "capacity is the size of the destination volume to create.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "cleanupTempPVC" = mkOption {
          description = "Set this to true to delete the temp destination PVC (dynamically provisioned\nby VolSync) at the end of each successful ReplicationDestination sync iteration.\nIf destinationPVC is set, this will have no effect, VolSync will only\ncleanup temp PVCs that it deployed.\nNote that if this is set to true, every sync this ReplicationDestination\nmakes will re-provision a new temp destination PVC and all data\nwill need to be sent again during the sync.\nDynamically provisioned destination PVCs will always be deleted if the\nowning ReplicationDestination is removed, even if this setting is false.\nThe default is false.";
          type = (types.nullOr types.bool);
        };
        "copyMethod" = mkOption {
          description = "copyMethod describes how a point-in-time (PiT) image of the destination\nvolume should be created.";
          type = (
            types.nullOr (
              types.enum [
                "Direct"
                "None"
                "Clone"
                "Snapshot"
              ]
            )
          );
        };
        "destinationPVC" = mkOption {
          description = "destinationPVC is a PVC to use as the transfer destination instead of\nautomatically provisioning one. Either this field or both capacity and\naccessModes must be specified.";
          type = (types.nullOr types.str);
        };
        "moverPodLabels" = mkOption {
          description = "Labels that should be added to data mover pods\nThese will be in addition to any labels that VolSync may add";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "moverResources" = mkOption {
          description = "Resources represents compute resources required by the data mover container.\nImmutable.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/\nThis should only be used by advanced users as this can result in a mover\npod being unschedulable or crashing due to limited resources.";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncMoverResources")
          );
        };
        "moverServiceAccount" = mkOption {
          description = "MoverServiceAccount allows specifying the name of the service account\nthat will be used by the data mover. This should only be used by advanced\nusers who want to override the service account normally used by the mover.\nThe service account needs to exist in the same namespace as the ReplicationDestination.";
          type = (types.nullOr types.str);
        };
        "path" = mkOption {
          description = "This field is not used and will be ignored";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "port is the SSH port to connect to for replication. Defaults to 22.";
          type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 0 types.int)));
        };
        "serviceAnnotations" = mkOption {
          description = "serviceAnnotations defines annotations that will be added to the\nservice created for incoming SSH connections.  If set, these annotations\nwill be used instead of any VolSync default values.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "serviceType" = mkOption {
          description = "serviceType determines the Service type that will be created for incoming\nSSH connections.";
          type = (types.nullOr types.str);
        };
        "sshKeys" = mkOption {
          description = "sshKeys is the name of a Secret that contains the SSH keys to be used for\nauthentication. If not provided, the keys will be generated.";
          type = (types.nullOr types.str);
        };
        "sshUser" = mkOption {
          description = "sshUser is the username for outgoing SSH connections. Defaults to \"root\".";
          type = (types.nullOr types.str);
        };
        "storageClassName" = mkOption {
          description = "storageClassName can be used to specify the StorageClass of the\ndestination volume. If not set, the default StorageClass will be used.";
          type = (types.nullOr types.str);
        };
        "volumeMode" = mkOption {
          description = "Will be used for the dynamic destination PVC created by VolSync.\nDefaults to \"Filesystem\"";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotClassName" = mkOption {
          description = "volumeSnapshotClassName can be used to specify the VSC to be used if\ncopyMethod is Snapshot. If not set, the default VSC is used.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "address" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "cleanupTempPVC" = mkOverride 1002 null;
        "copyMethod" = mkOverride 1002 null;
        "destinationPVC" = mkOverride 1002 null;
        "moverPodLabels" = mkOverride 1002 null;
        "moverResources" = mkOverride 1002 null;
        "moverServiceAccount" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "serviceAnnotations" = mkOverride 1002 null;
        "serviceType" = mkOverride 1002 null;
        "sshKeys" = mkOverride 1002 null;
        "sshUser" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "volumeMode" = mkOverride 1002 null;
        "volumeSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncMoverResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncMoverResourcesClaims"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncMoverResourcesClaims" = {

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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLS" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes specifies the access modes for the destination volume.";
          type = (types.nullOr (types.listOf types.str));
        };
        "capacity" = mkOption {
          description = "capacity is the size of the destination volume to create.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "cleanupTempPVC" = mkOption {
          description = "Set this to true to delete the temp destination PVC (dynamically provisioned\nby VolSync) at the end of each successful ReplicationDestination sync iteration.\nIf destinationPVC is set, this will have no effect, VolSync will only\ncleanup temp PVCs that it deployed.\nNote that if this is set to true, every sync this ReplicationDestination\nmakes will re-provision a new temp destination PVC and all data\nwill need to be sent again during the sync.\nDynamically provisioned destination PVCs will always be deleted if the\nowning ReplicationDestination is removed, even if this setting is false.\nThe default is false.";
          type = (types.nullOr types.bool);
        };
        "copyMethod" = mkOption {
          description = "copyMethod describes how a point-in-time (PiT) image of the destination\nvolume should be created.";
          type = (
            types.nullOr (
              types.enum [
                "Direct"
                "None"
                "Clone"
                "Snapshot"
              ]
            )
          );
        };
        "destinationPVC" = mkOption {
          description = "destinationPVC is a PVC to use as the transfer destination instead of\nautomatically provisioning one. Either this field or both capacity and\naccessModes must be specified.";
          type = (types.nullOr types.str);
        };
        "keySecret" = mkOption {
          description = "keySecret is the name of a Secret that contains the TLS pre-shared key to\nbe used for authentication. If not provided, the key will be generated.";
          type = (types.nullOr types.str);
        };
        "moverAffinity" = mkOption {
          description = "MoverAffinity allows specifying the PodAffinity that will be used by the data mover";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinity"
            )
          );
        };
        "moverPodLabels" = mkOption {
          description = "Labels that should be added to data mover pods\nThese will be in addition to any labels that VolSync may add";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "moverResources" = mkOption {
          description = "Resources represents compute resources required by the data mover container.\nImmutable.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/\nThis should only be used by advanced users as this can result in a mover\npod being unschedulable or crashing due to limited resources.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverResources"
            )
          );
        };
        "moverSecurityContext" = mkOption {
          description = "MoverSecurityContext allows specifying the PodSecurityContext that will\nbe used by the data mover";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContext"
            )
          );
        };
        "moverServiceAccount" = mkOption {
          description = "MoverServiceAccount allows specifying the name of the service account\nthat will be used by the data mover. This should only be used by advanced\nusers who want to override the service account normally used by the mover.\nThe service account needs to exist in the same namespace as this CR.";
          type = (types.nullOr types.str);
        };
        "moverVolumes" = mkOption {
          description = "MoverVolumes are PVCs or Secrets that should additionally be mounted to the mover job pod.\nThis should only be used by advanced users.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumes")
            )
          );
        };
        "serviceAnnotations" = mkOption {
          description = "serviceAnnotations defines annotations that will be added to the\nservice created for incoming SSH connections.  If set, these annotations\nwill be used instead of any VolSync default values.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "serviceType" = mkOption {
          description = "serviceType determines the Service type that will be created for incoming\nTLS connections.";
          type = (types.nullOr types.str);
        };
        "storageClassName" = mkOption {
          description = "storageClassName can be used to specify the StorageClass of the\ndestination volume. If not set, the default StorageClass will be used.";
          type = (types.nullOr types.str);
        };
        "volumeMode" = mkOption {
          description = "Will be used for the dynamic destination PVC created by VolSync.\nDefaults to \"Filesystem\"";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotClassName" = mkOption {
          description = "volumeSnapshotClassName can be used to specify the VSC to be used if\ncopyMethod is Snapshot. If not set, the default VSC is used.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "cleanupTempPVC" = mkOverride 1002 null;
        "copyMethod" = mkOverride 1002 null;
        "destinationPVC" = mkOverride 1002 null;
        "keySecret" = mkOverride 1002 null;
        "moverAffinity" = mkOverride 1002 null;
        "moverPodLabels" = mkOverride 1002 null;
        "moverResources" = mkOverride 1002 null;
        "moverSecurityContext" = mkOverride 1002 null;
        "moverServiceAccount" = mkOverride 1002 null;
        "moverVolumes" = mkOverride 1002 null;
        "serviceAnnotations" = mkOverride 1002 null;
        "serviceType" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "volumeMode" = mkOverride 1002 null;
        "volumeSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinity"
            )
          );
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinity"
            )
          );
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinity"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node matches the corresponding matchExpressions; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to an update), the system\nmay or may not try to eventually evict the pod from its node.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A node selector term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe anti-affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling anti-affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and subtracting\n\"weight\" from the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the anti-affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverResourcesClaims"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverResourcesClaims" = {

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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContext" = {

      options = {
        "appArmorProfile" = mkOption {
          description = "appArmorProfile is the AppArmor options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContextAppArmorProfile"
            )
          );
        };
        "fsGroup" = mkOption {
          description = "A special supplemental group that applies to all containers in a pod.\nSome volume types allow the Kubelet to change the ownership of that volume\nto be owned by the pod:\n\n1. The owning GID will be the FSGroup\n2. The setgid bit is set (new files created in the volume will be owned by FSGroup)\n3. The permission bits are OR'd with rw-rw----\n\nIf unset, the Kubelet will not modify the ownership and permissions of any volume.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "fsGroupChangePolicy" = mkOption {
          description = "fsGroupChangePolicy defines behavior of changing ownership and permission of the volume\nbefore being exposed inside Pod. This field will only apply to\nvolume types which support fsGroup based ownership(and permissions).\nIt will have no effect on ephemeral volume types such as: secret, configmaps\nand emptydir.\nValid values are \"OnRootMismatch\" and \"Always\". If not specified, \"Always\" is used.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "runAsGroup" = mkOption {
          description = "The GID to run the entrypoint of the container process.\nUses runtime default if unset.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "Indicates that the container must run as a non-root user.\nIf true, the Kubelet will validate the image at runtime to ensure that it\ndoes not run as UID 0 (root) and fail to start the container if it does.\nIf unset or false, no such validation will be performed.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "The UID to run the entrypoint of the container process.\nDefaults to user specified in image metadata if unspecified.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "seLinuxChangePolicy" = mkOption {
          description = "seLinuxChangePolicy defines how the container's SELinux label is applied to all volumes used by the Pod.\nIt has no effect on nodes that do not support SELinux or to volumes does not support SELinux.\nValid values are \"MountOption\" and \"Recursive\".\n\n\"Recursive\" means relabeling of all files on all Pod volumes by the container runtime.\nThis may be slow for large volumes, but allows mixing privileged and unprivileged Pods sharing the same volume on the same node.\n\n\"MountOption\" mounts all eligible Pod volumes with `-o context` mount option.\nThis requires all Pods that share the same volume to use the same SELinux label.\nIt is not possible to share the same volume among privileged and unprivileged Pods.\nEligible volumes are in-tree FibreChannel and iSCSI volumes, and all CSI volumes\nwhose CSI driver announces SELinux support by setting spec.seLinuxMount: true in their\nCSIDriver instance. Other volumes are always re-labelled recursively.\n\"MountOption\" value is allowed only when SELinuxMount feature gate is enabled.\n\nIf not specified and SELinuxMount feature gate is enabled, \"MountOption\" is used.\nIf not specified and SELinuxMount feature gate is disabled, \"MountOption\" is used for ReadWriteOncePod volumes\nand \"Recursive\" for all other volumes.\n\nThis field affects only Pods that have SELinux label set, either in PodSecurityContext or in SecurityContext of all containers.\n\nAll Pods that use the same volume should use the same seLinuxChangePolicy, otherwise some pods can get stuck in ContainerCreating state.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "seLinuxOptions" = mkOption {
          description = "The SELinux context to be applied to all containers.\nIf unspecified, the container runtime will allocate a random SELinux context for each\ncontainer.  May also be set in SecurityContext.  If set in\nboth SecurityContext and PodSecurityContext, the value specified in SecurityContext\ntakes precedence for that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContextSeLinuxOptions"
            )
          );
        };
        "seccompProfile" = mkOption {
          description = "The seccomp options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContextSeccompProfile"
            )
          );
        };
        "supplementalGroups" = mkOption {
          description = "A list of groups applied to the first process run in each container, in\naddition to the container's primary GID and fsGroup (if specified).  If\nthe SupplementalGroupsPolicy feature is enabled, the\nsupplementalGroupsPolicy field determines whether these are in addition\nto or instead of any group memberships defined in the container image.\nIf unspecified, no additional groups are added, though group memberships\ndefined in the container image may still be used, depending on the\nsupplementalGroupsPolicy field.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (types.listOf types.int));
        };
        "supplementalGroupsPolicy" = mkOption {
          description = "Defines how supplemental groups of the first container processes are calculated.\nValid values are \"Merge\" and \"Strict\". If not specified, \"Merge\" is used.\n(Alpha) Using the field requires the SupplementalGroupsPolicy feature gate to be enabled\nand the container runtime must implement support for this feature.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "sysctls" = mkOption {
          description = "Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported\nsysctls (by the container runtime) might fail to launch.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContextSysctls"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "windowsOptions" = mkOption {
          description = "The Windows specific settings applied to all containers.\nIf unspecified, the options within a container's SecurityContext will be used.\nIf set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.\nNote that this field cannot be set when spec.os.name is linux.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContextWindowsOptions"
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContextAppArmorProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile loaded on the node that should be used.\nThe profile must be preconfigured on the node to work.\nMust match the loaded name of the profile.\nMust be set if and only if type is \"Localhost\".";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of AppArmor profile will be applied.\nValid options are:\n  Localhost - a profile pre-loaded on the node.\n  RuntimeDefault - the container runtime's default profile.\n  Unconfined - no AppArmor enforcement.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContextSeLinuxOptions" = {

      options = {
        "level" = mkOption {
          description = "Level is SELinux level label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "Role is a SELinux role label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type is a SELinux type label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "User is a SELinux user label that applies to the container.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContextSeccompProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile defined in a file on the node should be used.\nThe profile must be preconfigured on the node to work.\nMust be a descending path, relative to the kubelet's configured seccomp profile location.\nMust be set if type is \"Localhost\". Must NOT be set for any other type.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of seccomp profile will be applied.\nValid options are:\n\nLocalhost - a profile defined in a file on the node should be used.\nRuntimeDefault - the container runtime default profile should be used.\nUnconfined - no profile should be applied.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContextSysctls" = {

      options = {
        "name" = mkOption {
          description = "Name of a property to set";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value of a property to set";
          type = types.str;
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverSecurityContextWindowsOptions" = {

      options = {
        "gmsaCredentialSpec" = mkOption {
          description = "GMSACredentialSpec is where the GMSA admission webhook\n(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the\nGMSA credential spec named by the GMSACredentialSpecName field.";
          type = (types.nullOr types.str);
        };
        "gmsaCredentialSpecName" = mkOption {
          description = "GMSACredentialSpecName is the name of the GMSA credential spec to use.";
          type = (types.nullOr types.str);
        };
        "hostProcess" = mkOption {
          description = "HostProcess determines if a container should be run as a 'Host Process' container.\nAll of a Pod's containers must have the same effective HostProcess value\n(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).\nIn addition, if HostProcess is true then HostNetwork must also be set to true.";
          type = (types.nullOr types.bool);
        };
        "runAsUserName" = mkOption {
          description = "The UserName in Windows to run the entrypoint of the container process.\nDefaults to the user specified in image metadata if unspecified.\nMay also be set in PodSecurityContext. If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumes" = {

      options = {
        "mountPath" = mkOption {
          description = "Path to give the volume when mounting under /mnt in the mover job pod.\nFor example if mountPath is 'my-pvc' then this moverVolume will be mounted in the mover pod\nat /mnt/my-pvc";
          type = types.str;
        };
        "volumeSource" = mkOption {
          description = "volumeSource represents the secret or PersistentVolumeClaim that should be mounted to the mover pod.";
          type = (
            submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumesVolumeSource"
          );
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumesVolumeSource" = {

      options = {
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host that shares a pod's lifetime\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumesVolumeSourceNfs"
            )
          );
        };
        "persistentVolumeClaim" = mkOption {
          description = "persistentVolumeClaimVolumeSource represents a reference to a\nPersistentVolumeClaim in the same namespace.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims\nnolint:lll";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumesVolumeSourcePersistentVolumeClaim"
            )
          );
        };
        "secret" = mkOption {
          description = "secret represents a secret that should populate this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumesVolumeSourceSecret"
            )
          );
        };
      };

      config = {
        "nfs" = mkOverride 1002 null;
        "persistentVolumeClaim" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumesVolumeSourceNfs" = {

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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumesVolumeSourcePersistentVolumeClaim" =
      {

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
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumesVolumeSourceSecret" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is Optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values\nfor mode bits. Defaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items If unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumesVolumeSourceSecretItems"
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
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecRsyncTLSMoverVolumesVolumeSourceSecretItems" = {

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
      };

      config = {
        "mode" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationSpecTrigger" = {

      options = {
        "manual" = mkOption {
          description = "manual is a string value that schedules a manual trigger.\nOnce a sync completes then status.lastManualSync is set to the same string value.\nA consumer of a manual trigger should set spec.trigger.manual to a known value\nand then wait for lastManualSync to be updated by the operator to the same value,\nwhich means that the manual trigger will then pause and wait for further\nupdates to the trigger.";
          type = (types.nullOr types.str);
        };
        "schedule" = mkOption {
          description = "schedule is a cronspec (https://en.wikipedia.org/wiki/Cron#Overview) that\ncan be used to schedule replication to occur at regular, time-based\nintervals.\nnolint:lll";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "manual" = mkOverride 1002 null;
        "schedule" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationStatus" = {

      options = {
        "conditions" = mkOption {
          description = "conditions represent the latest available observations of the\ndestination's state.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationStatusConditions")
            )
          );
        };
        "external" = mkOption {
          description = "external contains provider-specific status information. For more details,\nplease see the documentation of the specific replication provider being\nused.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "lastManualSync" = mkOption {
          description = "lastManualSync is set to the last spec.trigger.manual when the manual sync is done.";
          type = (types.nullOr types.str);
        };
        "lastSyncDuration" = mkOption {
          description = "lastSyncDuration is the amount of time required to send the most recent\nupdate.";
          type = (types.nullOr types.str);
        };
        "lastSyncStartTime" = mkOption {
          description = "lastSyncStartTime is the time the most recent synchronization started.";
          type = (types.nullOr types.str);
        };
        "lastSyncTime" = mkOption {
          description = "lastSyncTime is the time of the most recent successful synchronization.";
          type = (types.nullOr types.str);
        };
        "latestImage" = mkOption {
          description = "latestImage in the object holding the most recent consistent replicated\nimage.";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationStatusLatestImage")
          );
        };
        "latestMoverStatus" = mkOption {
          description = "Logs/Summary from latest mover job";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationStatusLatestMoverStatus")
          );
        };
        "nextSyncTime" = mkOption {
          description = "nextSyncTime is the time when the next volume synchronization is\nscheduled to start (for schedule-based synchronization).";
          type = (types.nullOr types.str);
        };
        "rsync" = mkOption {
          description = "rsync contains status information for Rsync-based replication.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationStatusRsync"));
        };
        "rsyncTLS" = mkOption {
          description = "rsyncTLS contains status information for Rsync-based replication over TLS.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationDestinationStatusRsyncTLS"));
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "external" = mkOverride 1002 null;
        "lastManualSync" = mkOverride 1002 null;
        "lastSyncDuration" = mkOverride 1002 null;
        "lastSyncStartTime" = mkOverride 1002 null;
        "lastSyncTime" = mkOverride 1002 null;
        "latestImage" = mkOverride 1002 null;
        "latestMoverStatus" = mkOverride 1002 null;
        "nextSyncTime" = mkOverride 1002 null;
        "rsync" = mkOverride 1002 null;
        "rsyncTLS" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationStatusConditions" = {

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
    "volsync.backube.v1alpha1.ReplicationDestinationStatusLatestImage" = {

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
    "volsync.backube.v1alpha1.ReplicationDestinationStatusLatestMoverStatus" = {

      options = {
        "logs" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "result" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "logs" = mkOverride 1002 null;
        "result" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationStatusRsync" = {

      options = {
        "address" = mkOption {
          description = "address is the address to connect to for incoming SSH replication\nconnections.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "port is the SSH port to connect to for incoming SSH replication\nconnections.";
          type = (types.nullOr types.int);
        };
        "sshKeys" = mkOption {
          description = "sshKeys is the name of a Secret that contains the SSH keys to be used for\nauthentication. If not provided in .spec.rsync.sshKeys, SSH keys will be\ngenerated and the appropriate keys for the remote side will be placed\nhere.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "address" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sshKeys" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationDestinationStatusRsyncTLS" = {

      options = {
        "address" = mkOption {
          description = "address is the address to connect to for incoming TLS connections.";
          type = (types.nullOr types.str);
        };
        "keySecret" = mkOption {
          description = "keySecret is the name of a Secret that contains the TLS pre-shared key to\nbe used for authentication. If not provided in .spec.rsyncTLS.keySecret,\nthe key Secret will be generated and named here.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "port is the port to connect to for incoming replication connections.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "address" = mkOverride 1002 null;
        "keySecret" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSource" = {

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
          description = "spec is the desired state of the ReplicationSource, including the\nreplication method to use and its configuration.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpec"));
        };
        "status" = mkOption {
          description = "status is the observed state of the ReplicationSource as determined by\nthe controller.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceStatus"));
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
    "volsync.backube.v1alpha1.ReplicationSourceSpec" = {

      options = {
        "external" = mkOption {
          description = "external defines the configuration when using an external replication\nprovider.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecExternal"));
        };
        "paused" = mkOption {
          description = "paused can be used to temporarily stop replication. Defaults to \"false\".";
          type = (types.nullOr types.bool);
        };
        "rclone" = mkOption {
          description = "rclone defines the configuration when using Rclone-based replication.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRclone"));
        };
        "restic" = mkOption {
          description = "restic defines the configuration when using Restic-based replication.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRestic"));
        };
        "rsync" = mkOption {
          description = "rsync defines the configuration when using Rsync-based replication.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsync"));
        };
        "rsyncTLS" = mkOption {
          description = "rsyncTLS defines the configuration when using Rsync-based replication over TLS.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLS"));
        };
        "sourcePVC" = mkOption {
          description = "sourcePVC is the name of the PersistentVolumeClaim (PVC) to replicate.";
          type = (types.nullOr types.str);
        };
        "syncthing" = mkOption {
          description = "syncthing defines the configuration when using Syncthing-based replication.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthing"));
        };
        "trigger" = mkOption {
          description = "trigger determines when the latest state of the volume will be captured\n(and potentially replicated to the destination).";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecTrigger"));
        };
      };

      config = {
        "external" = mkOverride 1002 null;
        "paused" = mkOverride 1002 null;
        "rclone" = mkOverride 1002 null;
        "restic" = mkOverride 1002 null;
        "rsync" = mkOverride 1002 null;
        "rsyncTLS" = mkOverride 1002 null;
        "sourcePVC" = mkOverride 1002 null;
        "syncthing" = mkOverride 1002 null;
        "trigger" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecExternal" = {

      options = {
        "parameters" = mkOption {
          description = "parameters are provider-specific key/value configuration parameters. For\nmore information, please see the documentation of the specific\nreplication provider being used.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "provider" = mkOption {
          description = "provider is the name of the external replication provider. The name\nshould be of the form: domain.com/provider.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "parameters" = mkOverride 1002 null;
        "provider" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRclone" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes can be used to override the accessModes of the PiT image.";
          type = (types.nullOr (types.listOf types.str));
        };
        "capacity" = mkOption {
          description = "capacity can be used to override the capacity of the PiT image.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "copyMethod" = mkOption {
          description = "copyMethod describes how a point-in-time (PiT) image of the source volume\nshould be created.";
          type = (
            types.nullOr (
              types.enum [
                "Direct"
                "None"
                "Clone"
                "Snapshot"
              ]
            )
          );
        };
        "customCA" = mkOption {
          description = "customCA is a custom CA that will be used to verify the remote";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneCustomCA"));
        };
        "moverAffinity" = mkOption {
          description = "MoverAffinity allows specifying the PodAffinity that will be used by the data mover";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinity")
          );
        };
        "moverPodLabels" = mkOption {
          description = "Labels that should be added to data mover pods\nThese will be in addition to any labels that VolSync may add";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "moverResources" = mkOption {
          description = "Resources represents compute resources required by the data mover container.\nImmutable.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/\nThis should only be used by advanced users as this can result in a mover\npod being unschedulable or crashing due to limited resources.";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverResources")
          );
        };
        "moverSecurityContext" = mkOption {
          description = "MoverSecurityContext allows specifying the PodSecurityContext that will\nbe used by the data mover";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContext"
            )
          );
        };
        "moverServiceAccount" = mkOption {
          description = "MoverServiceAccount allows specifying the name of the service account\nthat will be used by the data mover. This should only be used by advanced\nusers who want to override the service account normally used by the mover.\nThe service account needs to exist in the same namespace as this CR.";
          type = (types.nullOr types.str);
        };
        "moverVolumes" = mkOption {
          description = "MoverVolumes are PVCs or Secrets that should additionally be mounted to the mover job pod.\nThis should only be used by advanced users.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumes")
            )
          );
        };
        "rcloneConfig" = mkOption {
          description = "RcloneConfig is the rclone secret name";
          type = (types.nullOr types.str);
        };
        "rcloneConfigSection" = mkOption {
          description = "RcloneConfigSection is the section in rclone_config file to use for the current job.";
          type = (types.nullOr types.str);
        };
        "rcloneDestPath" = mkOption {
          description = "RcloneDestPath is the remote path to sync to.";
          type = (types.nullOr types.str);
        };
        "storageClassName" = mkOption {
          description = "storageClassName can be used to override the StorageClass of the PiT\nimage.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotClassName" = mkOption {
          description = "volumeSnapshotClassName can be used to specify the VSC to be used if\ncopyMethod is Snapshot. If not set, the default VSC is used.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "copyMethod" = mkOverride 1002 null;
        "customCA" = mkOverride 1002 null;
        "moverAffinity" = mkOverride 1002 null;
        "moverPodLabels" = mkOverride 1002 null;
        "moverResources" = mkOverride 1002 null;
        "moverSecurityContext" = mkOverride 1002 null;
        "moverServiceAccount" = mkOverride 1002 null;
        "moverVolumes" = mkOverride 1002 null;
        "rcloneConfig" = mkOverride 1002 null;
        "rcloneConfigSection" = mkOverride 1002 null;
        "rcloneDestPath" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "volumeSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneCustomCA" = {

      options = {
        "configMapName" = mkOption {
          description = "The name of a ConfigMap that contains the custom CA certificate\nIf ConfigMapName is used then SecretName should not be set";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "The key within the Secret or ConfigMap containing the CA certificate";
          type = (types.nullOr types.str);
        };
        "secretName" = mkOption {
          description = "The name of a Secret that contains the custom CA certificate\nIf SecretName is used then ConfigMapName should not be set";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "configMapName" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinity"
            )
          );
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinity"
            )
          );
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinity"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node matches the corresponding matchExpressions; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to an update), the system\nmay or may not try to eventually evict the pod from its node.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A node selector term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe anti-affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling anti-affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and subtracting\n\"weight\" from the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the anti-affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverResourcesClaims"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverResourcesClaims" = {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContext" = {

      options = {
        "appArmorProfile" = mkOption {
          description = "appArmorProfile is the AppArmor options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContextAppArmorProfile"
            )
          );
        };
        "fsGroup" = mkOption {
          description = "A special supplemental group that applies to all containers in a pod.\nSome volume types allow the Kubelet to change the ownership of that volume\nto be owned by the pod:\n\n1. The owning GID will be the FSGroup\n2. The setgid bit is set (new files created in the volume will be owned by FSGroup)\n3. The permission bits are OR'd with rw-rw----\n\nIf unset, the Kubelet will not modify the ownership and permissions of any volume.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "fsGroupChangePolicy" = mkOption {
          description = "fsGroupChangePolicy defines behavior of changing ownership and permission of the volume\nbefore being exposed inside Pod. This field will only apply to\nvolume types which support fsGroup based ownership(and permissions).\nIt will have no effect on ephemeral volume types such as: secret, configmaps\nand emptydir.\nValid values are \"OnRootMismatch\" and \"Always\". If not specified, \"Always\" is used.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "runAsGroup" = mkOption {
          description = "The GID to run the entrypoint of the container process.\nUses runtime default if unset.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "Indicates that the container must run as a non-root user.\nIf true, the Kubelet will validate the image at runtime to ensure that it\ndoes not run as UID 0 (root) and fail to start the container if it does.\nIf unset or false, no such validation will be performed.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "The UID to run the entrypoint of the container process.\nDefaults to user specified in image metadata if unspecified.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "seLinuxChangePolicy" = mkOption {
          description = "seLinuxChangePolicy defines how the container's SELinux label is applied to all volumes used by the Pod.\nIt has no effect on nodes that do not support SELinux or to volumes does not support SELinux.\nValid values are \"MountOption\" and \"Recursive\".\n\n\"Recursive\" means relabeling of all files on all Pod volumes by the container runtime.\nThis may be slow for large volumes, but allows mixing privileged and unprivileged Pods sharing the same volume on the same node.\n\n\"MountOption\" mounts all eligible Pod volumes with `-o context` mount option.\nThis requires all Pods that share the same volume to use the same SELinux label.\nIt is not possible to share the same volume among privileged and unprivileged Pods.\nEligible volumes are in-tree FibreChannel and iSCSI volumes, and all CSI volumes\nwhose CSI driver announces SELinux support by setting spec.seLinuxMount: true in their\nCSIDriver instance. Other volumes are always re-labelled recursively.\n\"MountOption\" value is allowed only when SELinuxMount feature gate is enabled.\n\nIf not specified and SELinuxMount feature gate is enabled, \"MountOption\" is used.\nIf not specified and SELinuxMount feature gate is disabled, \"MountOption\" is used for ReadWriteOncePod volumes\nand \"Recursive\" for all other volumes.\n\nThis field affects only Pods that have SELinux label set, either in PodSecurityContext or in SecurityContext of all containers.\n\nAll Pods that use the same volume should use the same seLinuxChangePolicy, otherwise some pods can get stuck in ContainerCreating state.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "seLinuxOptions" = mkOption {
          description = "The SELinux context to be applied to all containers.\nIf unspecified, the container runtime will allocate a random SELinux context for each\ncontainer.  May also be set in SecurityContext.  If set in\nboth SecurityContext and PodSecurityContext, the value specified in SecurityContext\ntakes precedence for that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContextSeLinuxOptions"
            )
          );
        };
        "seccompProfile" = mkOption {
          description = "The seccomp options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContextSeccompProfile"
            )
          );
        };
        "supplementalGroups" = mkOption {
          description = "A list of groups applied to the first process run in each container, in\naddition to the container's primary GID and fsGroup (if specified).  If\nthe SupplementalGroupsPolicy feature is enabled, the\nsupplementalGroupsPolicy field determines whether these are in addition\nto or instead of any group memberships defined in the container image.\nIf unspecified, no additional groups are added, though group memberships\ndefined in the container image may still be used, depending on the\nsupplementalGroupsPolicy field.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (types.listOf types.int));
        };
        "supplementalGroupsPolicy" = mkOption {
          description = "Defines how supplemental groups of the first container processes are calculated.\nValid values are \"Merge\" and \"Strict\". If not specified, \"Merge\" is used.\n(Alpha) Using the field requires the SupplementalGroupsPolicy feature gate to be enabled\nand the container runtime must implement support for this feature.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "sysctls" = mkOption {
          description = "Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported\nsysctls (by the container runtime) might fail to launch.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContextSysctls"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "windowsOptions" = mkOption {
          description = "The Windows specific settings applied to all containers.\nIf unspecified, the options within a container's SecurityContext will be used.\nIf set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.\nNote that this field cannot be set when spec.os.name is linux.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContextWindowsOptions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContextAppArmorProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile loaded on the node that should be used.\nThe profile must be preconfigured on the node to work.\nMust match the loaded name of the profile.\nMust be set if and only if type is \"Localhost\".";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of AppArmor profile will be applied.\nValid options are:\n  Localhost - a profile pre-loaded on the node.\n  RuntimeDefault - the container runtime's default profile.\n  Unconfined - no AppArmor enforcement.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContextSeLinuxOptions" = {

      options = {
        "level" = mkOption {
          description = "Level is SELinux level label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "Role is a SELinux role label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type is a SELinux type label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "User is a SELinux user label that applies to the container.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContextSeccompProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile defined in a file on the node should be used.\nThe profile must be preconfigured on the node to work.\nMust be a descending path, relative to the kubelet's configured seccomp profile location.\nMust be set if type is \"Localhost\". Must NOT be set for any other type.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of seccomp profile will be applied.\nValid options are:\n\nLocalhost - a profile defined in a file on the node should be used.\nRuntimeDefault - the container runtime default profile should be used.\nUnconfined - no profile should be applied.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContextSysctls" = {

      options = {
        "name" = mkOption {
          description = "Name of a property to set";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value of a property to set";
          type = types.str;
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverSecurityContextWindowsOptions" = {

      options = {
        "gmsaCredentialSpec" = mkOption {
          description = "GMSACredentialSpec is where the GMSA admission webhook\n(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the\nGMSA credential spec named by the GMSACredentialSpecName field.";
          type = (types.nullOr types.str);
        };
        "gmsaCredentialSpecName" = mkOption {
          description = "GMSACredentialSpecName is the name of the GMSA credential spec to use.";
          type = (types.nullOr types.str);
        };
        "hostProcess" = mkOption {
          description = "HostProcess determines if a container should be run as a 'Host Process' container.\nAll of a Pod's containers must have the same effective HostProcess value\n(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).\nIn addition, if HostProcess is true then HostNetwork must also be set to true.";
          type = (types.nullOr types.bool);
        };
        "runAsUserName" = mkOption {
          description = "The UserName in Windows to run the entrypoint of the container process.\nDefaults to the user specified in image metadata if unspecified.\nMay also be set in PodSecurityContext. If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumes" = {

      options = {
        "mountPath" = mkOption {
          description = "Path to give the volume when mounting under /mnt in the mover job pod.\nFor example if mountPath is 'my-pvc' then this moverVolume will be mounted in the mover pod\nat /mnt/my-pvc";
          type = types.str;
        };
        "volumeSource" = mkOption {
          description = "volumeSource represents the secret or PersistentVolumeClaim that should be mounted to the mover pod.";
          type = (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumesVolumeSource");
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumesVolumeSource" = {

      options = {
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host that shares a pod's lifetime\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumesVolumeSourceNfs"
            )
          );
        };
        "persistentVolumeClaim" = mkOption {
          description = "persistentVolumeClaimVolumeSource represents a reference to a\nPersistentVolumeClaim in the same namespace.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims\nnolint:lll";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumesVolumeSourcePersistentVolumeClaim"
            )
          );
        };
        "secret" = mkOption {
          description = "secret represents a secret that should populate this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumesVolumeSourceSecret"
            )
          );
        };
      };

      config = {
        "nfs" = mkOverride 1002 null;
        "persistentVolumeClaim" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumesVolumeSourceNfs" = {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumesVolumeSourcePersistentVolumeClaim" =
      {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumesVolumeSourceSecret" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is Optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values\nfor mode bits. Defaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items If unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumesVolumeSourceSecretItems"
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
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRcloneMoverVolumesVolumeSourceSecretItems" = {

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
      };

      config = {
        "mode" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRestic" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes can be used to override the accessModes of the PiT image.";
          type = (types.nullOr (types.listOf types.str));
        };
        "cacheAccessModes" = mkOption {
          description = "CacheAccessModes can be used to set the accessModes of restic metadata cache volume";
          type = (types.nullOr (types.listOf types.str));
        };
        "cacheCapacity" = mkOption {
          description = "cacheCapacity can be used to set the size of the restic metadata cache volume";
          type = (types.nullOr (types.either types.int types.str));
        };
        "cacheStorageClassName" = mkOption {
          description = "cacheStorageClassName can be used to set the StorageClass of the restic\nmetadata cache volume";
          type = (types.nullOr types.str);
        };
        "capacity" = mkOption {
          description = "capacity can be used to override the capacity of the PiT image.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "copyMethod" = mkOption {
          description = "copyMethod describes how a point-in-time (PiT) image of the source volume\nshould be created.";
          type = (
            types.nullOr (
              types.enum [
                "Direct"
                "None"
                "Clone"
                "Snapshot"
              ]
            )
          );
        };
        "customCA" = mkOption {
          description = "customCA is a custom CA that will be used to verify the remote";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticCustomCA"));
        };
        "moverAffinity" = mkOption {
          description = "MoverAffinity allows specifying the PodAffinity that will be used by the data mover";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinity")
          );
        };
        "moverPodLabels" = mkOption {
          description = "Labels that should be added to data mover pods\nThese will be in addition to any labels that VolSync may add";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "moverResources" = mkOption {
          description = "Resources represents compute resources required by the data mover container.\nImmutable.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/\nThis should only be used by advanced users as this can result in a mover\npod being unschedulable or crashing due to limited resources.";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverResources")
          );
        };
        "moverSecurityContext" = mkOption {
          description = "MoverSecurityContext allows specifying the PodSecurityContext that will\nbe used by the data mover";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContext"
            )
          );
        };
        "moverServiceAccount" = mkOption {
          description = "MoverServiceAccount allows specifying the name of the service account\nthat will be used by the data mover. This should only be used by advanced\nusers who want to override the service account normally used by the mover.\nThe service account needs to exist in the same namespace as this CR.";
          type = (types.nullOr types.str);
        };
        "moverVolumes" = mkOption {
          description = "MoverVolumes are PVCs or Secrets that should additionally be mounted to the mover job pod.\nThis should only be used by advanced users.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumes")
            )
          );
        };
        "pruneIntervalDays" = mkOption {
          description = "PruneIntervalDays define how often to prune the repository";
          type = (types.nullOr types.int);
        };
        "repository" = mkOption {
          description = "Repository is the secret name containing repository info";
          type = (types.nullOr types.str);
        };
        "retain" = mkOption {
          description = "ResticRetainPolicy define the retain policy";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticRetain"));
        };
        "storageClassName" = mkOption {
          description = "storageClassName can be used to override the StorageClass of the PiT\nimage.";
          type = (types.nullOr types.str);
        };
        "unlock" = mkOption {
          description = "unlock is a string value that schedules an unlock on the restic repository during\nthe next sync operation.\nOnce a sync completes then status.restic.lastUnlocked is set to the same string value.\nTo unlock a repository, set spec.restic.unlock to a known value and then wait for\nlastUnlocked to be updated by the operator to the same value,\nwhich means that the sync unlocked the repository by running a restic unlock command and\nthen ran a backup.\nUnlock will not be run again unless spec.restic.unlock is set to a different value.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotClassName" = mkOption {
          description = "volumeSnapshotClassName can be used to specify the VSC to be used if\ncopyMethod is Snapshot. If not set, the default VSC is used.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "cacheAccessModes" = mkOverride 1002 null;
        "cacheCapacity" = mkOverride 1002 null;
        "cacheStorageClassName" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "copyMethod" = mkOverride 1002 null;
        "customCA" = mkOverride 1002 null;
        "moverAffinity" = mkOverride 1002 null;
        "moverPodLabels" = mkOverride 1002 null;
        "moverResources" = mkOverride 1002 null;
        "moverSecurityContext" = mkOverride 1002 null;
        "moverServiceAccount" = mkOverride 1002 null;
        "moverVolumes" = mkOverride 1002 null;
        "pruneIntervalDays" = mkOverride 1002 null;
        "repository" = mkOverride 1002 null;
        "retain" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "unlock" = mkOverride 1002 null;
        "volumeSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticCustomCA" = {

      options = {
        "configMapName" = mkOption {
          description = "The name of a ConfigMap that contains the custom CA certificate\nIf ConfigMapName is used then SecretName should not be set";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "The key within the Secret or ConfigMap containing the CA certificate";
          type = (types.nullOr types.str);
        };
        "secretName" = mkOption {
          description = "The name of a Secret that contains the custom CA certificate\nIf SecretName is used then ConfigMapName should not be set";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "configMapName" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinity"
            )
          );
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinity"
            )
          );
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinity"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node matches the corresponding matchExpressions; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to an update), the system\nmay or may not try to eventually evict the pod from its node.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A node selector term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe anti-affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling anti-affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and subtracting\n\"weight\" from the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the anti-affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverResourcesClaims"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverResourcesClaims" = {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContext" = {

      options = {
        "appArmorProfile" = mkOption {
          description = "appArmorProfile is the AppArmor options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContextAppArmorProfile"
            )
          );
        };
        "fsGroup" = mkOption {
          description = "A special supplemental group that applies to all containers in a pod.\nSome volume types allow the Kubelet to change the ownership of that volume\nto be owned by the pod:\n\n1. The owning GID will be the FSGroup\n2. The setgid bit is set (new files created in the volume will be owned by FSGroup)\n3. The permission bits are OR'd with rw-rw----\n\nIf unset, the Kubelet will not modify the ownership and permissions of any volume.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "fsGroupChangePolicy" = mkOption {
          description = "fsGroupChangePolicy defines behavior of changing ownership and permission of the volume\nbefore being exposed inside Pod. This field will only apply to\nvolume types which support fsGroup based ownership(and permissions).\nIt will have no effect on ephemeral volume types such as: secret, configmaps\nand emptydir.\nValid values are \"OnRootMismatch\" and \"Always\". If not specified, \"Always\" is used.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "runAsGroup" = mkOption {
          description = "The GID to run the entrypoint of the container process.\nUses runtime default if unset.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "Indicates that the container must run as a non-root user.\nIf true, the Kubelet will validate the image at runtime to ensure that it\ndoes not run as UID 0 (root) and fail to start the container if it does.\nIf unset or false, no such validation will be performed.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "The UID to run the entrypoint of the container process.\nDefaults to user specified in image metadata if unspecified.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "seLinuxChangePolicy" = mkOption {
          description = "seLinuxChangePolicy defines how the container's SELinux label is applied to all volumes used by the Pod.\nIt has no effect on nodes that do not support SELinux or to volumes does not support SELinux.\nValid values are \"MountOption\" and \"Recursive\".\n\n\"Recursive\" means relabeling of all files on all Pod volumes by the container runtime.\nThis may be slow for large volumes, but allows mixing privileged and unprivileged Pods sharing the same volume on the same node.\n\n\"MountOption\" mounts all eligible Pod volumes with `-o context` mount option.\nThis requires all Pods that share the same volume to use the same SELinux label.\nIt is not possible to share the same volume among privileged and unprivileged Pods.\nEligible volumes are in-tree FibreChannel and iSCSI volumes, and all CSI volumes\nwhose CSI driver announces SELinux support by setting spec.seLinuxMount: true in their\nCSIDriver instance. Other volumes are always re-labelled recursively.\n\"MountOption\" value is allowed only when SELinuxMount feature gate is enabled.\n\nIf not specified and SELinuxMount feature gate is enabled, \"MountOption\" is used.\nIf not specified and SELinuxMount feature gate is disabled, \"MountOption\" is used for ReadWriteOncePod volumes\nand \"Recursive\" for all other volumes.\n\nThis field affects only Pods that have SELinux label set, either in PodSecurityContext or in SecurityContext of all containers.\n\nAll Pods that use the same volume should use the same seLinuxChangePolicy, otherwise some pods can get stuck in ContainerCreating state.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "seLinuxOptions" = mkOption {
          description = "The SELinux context to be applied to all containers.\nIf unspecified, the container runtime will allocate a random SELinux context for each\ncontainer.  May also be set in SecurityContext.  If set in\nboth SecurityContext and PodSecurityContext, the value specified in SecurityContext\ntakes precedence for that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContextSeLinuxOptions"
            )
          );
        };
        "seccompProfile" = mkOption {
          description = "The seccomp options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContextSeccompProfile"
            )
          );
        };
        "supplementalGroups" = mkOption {
          description = "A list of groups applied to the first process run in each container, in\naddition to the container's primary GID and fsGroup (if specified).  If\nthe SupplementalGroupsPolicy feature is enabled, the\nsupplementalGroupsPolicy field determines whether these are in addition\nto or instead of any group memberships defined in the container image.\nIf unspecified, no additional groups are added, though group memberships\ndefined in the container image may still be used, depending on the\nsupplementalGroupsPolicy field.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (types.listOf types.int));
        };
        "supplementalGroupsPolicy" = mkOption {
          description = "Defines how supplemental groups of the first container processes are calculated.\nValid values are \"Merge\" and \"Strict\". If not specified, \"Merge\" is used.\n(Alpha) Using the field requires the SupplementalGroupsPolicy feature gate to be enabled\nand the container runtime must implement support for this feature.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "sysctls" = mkOption {
          description = "Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported\nsysctls (by the container runtime) might fail to launch.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContextSysctls"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "windowsOptions" = mkOption {
          description = "The Windows specific settings applied to all containers.\nIf unspecified, the options within a container's SecurityContext will be used.\nIf set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.\nNote that this field cannot be set when spec.os.name is linux.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContextWindowsOptions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContextAppArmorProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile loaded on the node that should be used.\nThe profile must be preconfigured on the node to work.\nMust match the loaded name of the profile.\nMust be set if and only if type is \"Localhost\".";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of AppArmor profile will be applied.\nValid options are:\n  Localhost - a profile pre-loaded on the node.\n  RuntimeDefault - the container runtime's default profile.\n  Unconfined - no AppArmor enforcement.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContextSeLinuxOptions" = {

      options = {
        "level" = mkOption {
          description = "Level is SELinux level label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "Role is a SELinux role label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type is a SELinux type label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "User is a SELinux user label that applies to the container.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContextSeccompProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile defined in a file on the node should be used.\nThe profile must be preconfigured on the node to work.\nMust be a descending path, relative to the kubelet's configured seccomp profile location.\nMust be set if type is \"Localhost\". Must NOT be set for any other type.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of seccomp profile will be applied.\nValid options are:\n\nLocalhost - a profile defined in a file on the node should be used.\nRuntimeDefault - the container runtime default profile should be used.\nUnconfined - no profile should be applied.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContextSysctls" = {

      options = {
        "name" = mkOption {
          description = "Name of a property to set";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value of a property to set";
          type = types.str;
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverSecurityContextWindowsOptions" = {

      options = {
        "gmsaCredentialSpec" = mkOption {
          description = "GMSACredentialSpec is where the GMSA admission webhook\n(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the\nGMSA credential spec named by the GMSACredentialSpecName field.";
          type = (types.nullOr types.str);
        };
        "gmsaCredentialSpecName" = mkOption {
          description = "GMSACredentialSpecName is the name of the GMSA credential spec to use.";
          type = (types.nullOr types.str);
        };
        "hostProcess" = mkOption {
          description = "HostProcess determines if a container should be run as a 'Host Process' container.\nAll of a Pod's containers must have the same effective HostProcess value\n(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).\nIn addition, if HostProcess is true then HostNetwork must also be set to true.";
          type = (types.nullOr types.bool);
        };
        "runAsUserName" = mkOption {
          description = "The UserName in Windows to run the entrypoint of the container process.\nDefaults to the user specified in image metadata if unspecified.\nMay also be set in PodSecurityContext. If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumes" = {

      options = {
        "mountPath" = mkOption {
          description = "Path to give the volume when mounting under /mnt in the mover job pod.\nFor example if mountPath is 'my-pvc' then this moverVolume will be mounted in the mover pod\nat /mnt/my-pvc";
          type = types.str;
        };
        "volumeSource" = mkOption {
          description = "volumeSource represents the secret or PersistentVolumeClaim that should be mounted to the mover pod.";
          type = (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumesVolumeSource");
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumesVolumeSource" = {

      options = {
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host that shares a pod's lifetime\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumesVolumeSourceNfs"
            )
          );
        };
        "persistentVolumeClaim" = mkOption {
          description = "persistentVolumeClaimVolumeSource represents a reference to a\nPersistentVolumeClaim in the same namespace.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims\nnolint:lll";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumesVolumeSourcePersistentVolumeClaim"
            )
          );
        };
        "secret" = mkOption {
          description = "secret represents a secret that should populate this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumesVolumeSourceSecret"
            )
          );
        };
      };

      config = {
        "nfs" = mkOverride 1002 null;
        "persistentVolumeClaim" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumesVolumeSourceNfs" = {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumesVolumeSourcePersistentVolumeClaim" =
      {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumesVolumeSourceSecret" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is Optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values\nfor mode bits. Defaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items If unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumesVolumeSourceSecretItems"
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
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticMoverVolumesVolumeSourceSecretItems" = {

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
      };

      config = {
        "mode" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecResticRetain" = {

      options = {
        "daily" = mkOption {
          description = "Daily defines the number of snapshots to be kept daily";
          type = (types.nullOr types.int);
        };
        "hourly" = mkOption {
          description = "Hourly defines the number of snapshots to be kept hourly";
          type = (types.nullOr types.int);
        };
        "last" = mkOption {
          description = "Last defines the number of snapshots to be kept";
          type = (types.nullOr types.str);
        };
        "monthly" = mkOption {
          description = "Monthly defines the number of snapshots to be kept monthly";
          type = (types.nullOr types.int);
        };
        "weekly" = mkOption {
          description = "Weekly defines the number of snapshots to be kept weekly";
          type = (types.nullOr types.int);
        };
        "within" = mkOption {
          description = "Within defines the number of snapshots to be kept Within the given time period";
          type = (types.nullOr types.str);
        };
        "yearly" = mkOption {
          description = "Yearly defines the number of snapshots to be kept yearly";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "daily" = mkOverride 1002 null;
        "hourly" = mkOverride 1002 null;
        "last" = mkOverride 1002 null;
        "monthly" = mkOverride 1002 null;
        "weekly" = mkOverride 1002 null;
        "within" = mkOverride 1002 null;
        "yearly" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsync" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes can be used to override the accessModes of the PiT image.";
          type = (types.nullOr (types.listOf types.str));
        };
        "address" = mkOption {
          description = "address is the remote address to connect to for replication.";
          type = (types.nullOr types.str);
        };
        "capacity" = mkOption {
          description = "capacity can be used to override the capacity of the PiT image.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "copyMethod" = mkOption {
          description = "copyMethod describes how a point-in-time (PiT) image of the source volume\nshould be created.";
          type = (
            types.nullOr (
              types.enum [
                "Direct"
                "None"
                "Clone"
                "Snapshot"
              ]
            )
          );
        };
        "moverPodLabels" = mkOption {
          description = "Labels that should be added to data mover pods\nThese will be in addition to any labels that VolSync may add";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "moverResources" = mkOption {
          description = "Resources represents compute resources required by the data mover container.\nImmutable.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/\nThis should only be used by advanced users as this can result in a mover\npod being unschedulable or crashing due to limited resources.";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncMoverResources")
          );
        };
        "moverServiceAccount" = mkOption {
          description = "MoverServiceAccount allows specifying the name of the service account\nthat will be used by the data mover. This should only be used by advanced\nusers who want to override the service account normally used by the mover.\nThe service account needs to exist in the same namespace as the ReplicationSource.";
          type = (types.nullOr types.str);
        };
        "path" = mkOption {
          description = "This field is not used and will be ignored";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "port is the SSH port to connect to for replication. Defaults to 22.";
          type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 0 types.int)));
        };
        "serviceType" = mkOption {
          description = "serviceType determines the Service type that will be created for incoming\nSSH connections.";
          type = (types.nullOr types.str);
        };
        "sshKeys" = mkOption {
          description = "sshKeys is the name of a Secret that contains the SSH keys to be used for\nauthentication. If not provided, the keys will be generated.";
          type = (types.nullOr types.str);
        };
        "sshUser" = mkOption {
          description = "sshUser is the username for outgoing SSH connections. Defaults to \"root\".";
          type = (types.nullOr types.str);
        };
        "storageClassName" = mkOption {
          description = "storageClassName can be used to override the StorageClass of the PiT\nimage.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotClassName" = mkOption {
          description = "volumeSnapshotClassName can be used to specify the VSC to be used if\ncopyMethod is Snapshot. If not set, the default VSC is used.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "address" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "copyMethod" = mkOverride 1002 null;
        "moverPodLabels" = mkOverride 1002 null;
        "moverResources" = mkOverride 1002 null;
        "moverServiceAccount" = mkOverride 1002 null;
        "path" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "serviceType" = mkOverride 1002 null;
        "sshKeys" = mkOverride 1002 null;
        "sshUser" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "volumeSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncMoverResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncMoverResourcesClaims"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncMoverResourcesClaims" = {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLS" = {

      options = {
        "accessModes" = mkOption {
          description = "accessModes can be used to override the accessModes of the PiT image.";
          type = (types.nullOr (types.listOf types.str));
        };
        "address" = mkOption {
          description = "address is the remote address to connect to for replication.";
          type = (types.nullOr types.str);
        };
        "capacity" = mkOption {
          description = "capacity can be used to override the capacity of the PiT image.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "copyMethod" = mkOption {
          description = "copyMethod describes how a point-in-time (PiT) image of the source volume\nshould be created.";
          type = (
            types.nullOr (
              types.enum [
                "Direct"
                "None"
                "Clone"
                "Snapshot"
              ]
            )
          );
        };
        "keySecret" = mkOption {
          description = "keySecret is the name of a Secret that contains the TLS pre-shared key to\nbe used for authentication. If not provided, the key will be generated.";
          type = (types.nullOr types.str);
        };
        "moverAffinity" = mkOption {
          description = "MoverAffinity allows specifying the PodAffinity that will be used by the data mover";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinity")
          );
        };
        "moverPodLabels" = mkOption {
          description = "Labels that should be added to data mover pods\nThese will be in addition to any labels that VolSync may add";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "moverResources" = mkOption {
          description = "Resources represents compute resources required by the data mover container.\nImmutable.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/\nThis should only be used by advanced users as this can result in a mover\npod being unschedulable or crashing due to limited resources.";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverResources")
          );
        };
        "moverSecurityContext" = mkOption {
          description = "MoverSecurityContext allows specifying the PodSecurityContext that will\nbe used by the data mover";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContext"
            )
          );
        };
        "moverServiceAccount" = mkOption {
          description = "MoverServiceAccount allows specifying the name of the service account\nthat will be used by the data mover. This should only be used by advanced\nusers who want to override the service account normally used by the mover.\nThe service account needs to exist in the same namespace as this CR.";
          type = (types.nullOr types.str);
        };
        "moverVolumes" = mkOption {
          description = "MoverVolumes are PVCs or Secrets that should additionally be mounted to the mover job pod.\nThis should only be used by advanced users.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumes")
            )
          );
        };
        "port" = mkOption {
          description = "port is the port to connect to for replication. Defaults to 8000.";
          type = (types.nullOr (types.withMaximum 65535 (types.withMinimum 0 types.int)));
        };
        "storageClassName" = mkOption {
          description = "storageClassName can be used to override the StorageClass of the PiT\nimage.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotClassName" = mkOption {
          description = "volumeSnapshotClassName can be used to specify the VSC to be used if\ncopyMethod is Snapshot. If not set, the default VSC is used.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "accessModes" = mkOverride 1002 null;
        "address" = mkOverride 1002 null;
        "capacity" = mkOverride 1002 null;
        "copyMethod" = mkOverride 1002 null;
        "keySecret" = mkOverride 1002 null;
        "moverAffinity" = mkOverride 1002 null;
        "moverPodLabels" = mkOverride 1002 null;
        "moverResources" = mkOverride 1002 null;
        "moverSecurityContext" = mkOverride 1002 null;
        "moverServiceAccount" = mkOverride 1002 null;
        "moverVolumes" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "storageClassName" = mkOverride 1002 null;
        "volumeSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinity"
            )
          );
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinity"
            )
          );
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinity"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node matches the corresponding matchExpressions; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to an update), the system\nmay or may not try to eventually evict the pod from its node.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A node selector term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe anti-affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling anti-affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and subtracting\n\"weight\" from the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the anti-affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverResourcesClaims"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverResourcesClaims" = {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContext" = {

      options = {
        "appArmorProfile" = mkOption {
          description = "appArmorProfile is the AppArmor options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContextAppArmorProfile"
            )
          );
        };
        "fsGroup" = mkOption {
          description = "A special supplemental group that applies to all containers in a pod.\nSome volume types allow the Kubelet to change the ownership of that volume\nto be owned by the pod:\n\n1. The owning GID will be the FSGroup\n2. The setgid bit is set (new files created in the volume will be owned by FSGroup)\n3. The permission bits are OR'd with rw-rw----\n\nIf unset, the Kubelet will not modify the ownership and permissions of any volume.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "fsGroupChangePolicy" = mkOption {
          description = "fsGroupChangePolicy defines behavior of changing ownership and permission of the volume\nbefore being exposed inside Pod. This field will only apply to\nvolume types which support fsGroup based ownership(and permissions).\nIt will have no effect on ephemeral volume types such as: secret, configmaps\nand emptydir.\nValid values are \"OnRootMismatch\" and \"Always\". If not specified, \"Always\" is used.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "runAsGroup" = mkOption {
          description = "The GID to run the entrypoint of the container process.\nUses runtime default if unset.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "Indicates that the container must run as a non-root user.\nIf true, the Kubelet will validate the image at runtime to ensure that it\ndoes not run as UID 0 (root) and fail to start the container if it does.\nIf unset or false, no such validation will be performed.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "The UID to run the entrypoint of the container process.\nDefaults to user specified in image metadata if unspecified.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "seLinuxChangePolicy" = mkOption {
          description = "seLinuxChangePolicy defines how the container's SELinux label is applied to all volumes used by the Pod.\nIt has no effect on nodes that do not support SELinux or to volumes does not support SELinux.\nValid values are \"MountOption\" and \"Recursive\".\n\n\"Recursive\" means relabeling of all files on all Pod volumes by the container runtime.\nThis may be slow for large volumes, but allows mixing privileged and unprivileged Pods sharing the same volume on the same node.\n\n\"MountOption\" mounts all eligible Pod volumes with `-o context` mount option.\nThis requires all Pods that share the same volume to use the same SELinux label.\nIt is not possible to share the same volume among privileged and unprivileged Pods.\nEligible volumes are in-tree FibreChannel and iSCSI volumes, and all CSI volumes\nwhose CSI driver announces SELinux support by setting spec.seLinuxMount: true in their\nCSIDriver instance. Other volumes are always re-labelled recursively.\n\"MountOption\" value is allowed only when SELinuxMount feature gate is enabled.\n\nIf not specified and SELinuxMount feature gate is enabled, \"MountOption\" is used.\nIf not specified and SELinuxMount feature gate is disabled, \"MountOption\" is used for ReadWriteOncePod volumes\nand \"Recursive\" for all other volumes.\n\nThis field affects only Pods that have SELinux label set, either in PodSecurityContext or in SecurityContext of all containers.\n\nAll Pods that use the same volume should use the same seLinuxChangePolicy, otherwise some pods can get stuck in ContainerCreating state.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "seLinuxOptions" = mkOption {
          description = "The SELinux context to be applied to all containers.\nIf unspecified, the container runtime will allocate a random SELinux context for each\ncontainer.  May also be set in SecurityContext.  If set in\nboth SecurityContext and PodSecurityContext, the value specified in SecurityContext\ntakes precedence for that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContextSeLinuxOptions"
            )
          );
        };
        "seccompProfile" = mkOption {
          description = "The seccomp options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContextSeccompProfile"
            )
          );
        };
        "supplementalGroups" = mkOption {
          description = "A list of groups applied to the first process run in each container, in\naddition to the container's primary GID and fsGroup (if specified).  If\nthe SupplementalGroupsPolicy feature is enabled, the\nsupplementalGroupsPolicy field determines whether these are in addition\nto or instead of any group memberships defined in the container image.\nIf unspecified, no additional groups are added, though group memberships\ndefined in the container image may still be used, depending on the\nsupplementalGroupsPolicy field.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (types.listOf types.int));
        };
        "supplementalGroupsPolicy" = mkOption {
          description = "Defines how supplemental groups of the first container processes are calculated.\nValid values are \"Merge\" and \"Strict\". If not specified, \"Merge\" is used.\n(Alpha) Using the field requires the SupplementalGroupsPolicy feature gate to be enabled\nand the container runtime must implement support for this feature.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "sysctls" = mkOption {
          description = "Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported\nsysctls (by the container runtime) might fail to launch.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContextSysctls"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "windowsOptions" = mkOption {
          description = "The Windows specific settings applied to all containers.\nIf unspecified, the options within a container's SecurityContext will be used.\nIf set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.\nNote that this field cannot be set when spec.os.name is linux.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContextWindowsOptions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContextAppArmorProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile loaded on the node that should be used.\nThe profile must be preconfigured on the node to work.\nMust match the loaded name of the profile.\nMust be set if and only if type is \"Localhost\".";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of AppArmor profile will be applied.\nValid options are:\n  Localhost - a profile pre-loaded on the node.\n  RuntimeDefault - the container runtime's default profile.\n  Unconfined - no AppArmor enforcement.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContextSeLinuxOptions" = {

      options = {
        "level" = mkOption {
          description = "Level is SELinux level label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "Role is a SELinux role label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type is a SELinux type label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "User is a SELinux user label that applies to the container.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContextSeccompProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile defined in a file on the node should be used.\nThe profile must be preconfigured on the node to work.\nMust be a descending path, relative to the kubelet's configured seccomp profile location.\nMust be set if type is \"Localhost\". Must NOT be set for any other type.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of seccomp profile will be applied.\nValid options are:\n\nLocalhost - a profile defined in a file on the node should be used.\nRuntimeDefault - the container runtime default profile should be used.\nUnconfined - no profile should be applied.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContextSysctls" = {

      options = {
        "name" = mkOption {
          description = "Name of a property to set";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value of a property to set";
          type = types.str;
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverSecurityContextWindowsOptions" = {

      options = {
        "gmsaCredentialSpec" = mkOption {
          description = "GMSACredentialSpec is where the GMSA admission webhook\n(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the\nGMSA credential spec named by the GMSACredentialSpecName field.";
          type = (types.nullOr types.str);
        };
        "gmsaCredentialSpecName" = mkOption {
          description = "GMSACredentialSpecName is the name of the GMSA credential spec to use.";
          type = (types.nullOr types.str);
        };
        "hostProcess" = mkOption {
          description = "HostProcess determines if a container should be run as a 'Host Process' container.\nAll of a Pod's containers must have the same effective HostProcess value\n(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).\nIn addition, if HostProcess is true then HostNetwork must also be set to true.";
          type = (types.nullOr types.bool);
        };
        "runAsUserName" = mkOption {
          description = "The UserName in Windows to run the entrypoint of the container process.\nDefaults to the user specified in image metadata if unspecified.\nMay also be set in PodSecurityContext. If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumes" = {

      options = {
        "mountPath" = mkOption {
          description = "Path to give the volume when mounting under /mnt in the mover job pod.\nFor example if mountPath is 'my-pvc' then this moverVolume will be mounted in the mover pod\nat /mnt/my-pvc";
          type = types.str;
        };
        "volumeSource" = mkOption {
          description = "volumeSource represents the secret or PersistentVolumeClaim that should be mounted to the mover pod.";
          type = (
            submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumesVolumeSource"
          );
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumesVolumeSource" = {

      options = {
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host that shares a pod's lifetime\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumesVolumeSourceNfs"
            )
          );
        };
        "persistentVolumeClaim" = mkOption {
          description = "persistentVolumeClaimVolumeSource represents a reference to a\nPersistentVolumeClaim in the same namespace.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims\nnolint:lll";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumesVolumeSourcePersistentVolumeClaim"
            )
          );
        };
        "secret" = mkOption {
          description = "secret represents a secret that should populate this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumesVolumeSourceSecret"
            )
          );
        };
      };

      config = {
        "nfs" = mkOverride 1002 null;
        "persistentVolumeClaim" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumesVolumeSourceNfs" = {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumesVolumeSourcePersistentVolumeClaim" =
      {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumesVolumeSourceSecret" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is Optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values\nfor mode bits. Defaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items If unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumesVolumeSourceSecretItems"
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
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecRsyncTLSMoverVolumesVolumeSourceSecretItems" = {

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
      };

      config = {
        "mode" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthing" = {

      options = {
        "configAccessModes" = mkOption {
          description = "Used to set the accessModes of Syncthing config volume.";
          type = (types.nullOr (types.listOf types.str));
        };
        "configCapacity" = mkOption {
          description = "Used to set the size of the Syncthing config volume.";
          type = (types.nullOr (types.either types.int types.str));
        };
        "configStorageClassName" = mkOption {
          description = "Used to set the StorageClass of the Syncthing config volume.";
          type = (types.nullOr types.str);
        };
        "moverAffinity" = mkOption {
          description = "MoverAffinity allows specifying the PodAffinity that will be used by the data mover";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinity")
          );
        };
        "moverPodLabels" = mkOption {
          description = "Labels that should be added to data mover pods\nThese will be in addition to any labels that VolSync may add";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "moverResources" = mkOption {
          description = "Resources represents compute resources required by the data mover container.\nImmutable.\nMore info: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/\nThis should only be used by advanced users as this can result in a mover\npod being unschedulable or crashing due to limited resources.";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverResources")
          );
        };
        "moverSecurityContext" = mkOption {
          description = "MoverSecurityContext allows specifying the PodSecurityContext that will\nbe used by the data mover";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContext"
            )
          );
        };
        "moverServiceAccount" = mkOption {
          description = "MoverServiceAccount allows specifying the name of the service account\nthat will be used by the data mover. This should only be used by advanced\nusers who want to override the service account normally used by the mover.\nThe service account needs to exist in the same namespace as this CR.";
          type = (types.nullOr types.str);
        };
        "moverVolumes" = mkOption {
          description = "MoverVolumes are PVCs or Secrets that should additionally be mounted to the mover job pod.\nThis should only be used by advanced users.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumes")
            )
          );
        };
        "peers" = mkOption {
          description = "List of Syncthing peers to be connected for syncing";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingPeers")
            )
          );
        };
        "serviceType" = mkOption {
          description = "Type of service to be used when exposing the Syncthing peer";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "configAccessModes" = mkOverride 1002 null;
        "configCapacity" = mkOverride 1002 null;
        "configStorageClassName" = mkOverride 1002 null;
        "moverAffinity" = mkOverride 1002 null;
        "moverPodLabels" = mkOverride 1002 null;
        "moverResources" = mkOverride 1002 null;
        "moverSecurityContext" = mkOverride 1002 null;
        "moverServiceAccount" = mkOverride 1002 null;
        "moverVolumes" = mkOverride 1002 null;
        "peers" = mkOverride 1002 null;
        "serviceType" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinity" = {

      options = {
        "nodeAffinity" = mkOption {
          description = "Describes node affinity scheduling rules for the pod.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinity"
            )
          );
        };
        "podAffinity" = mkOption {
          description = "Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinity"
            )
          );
        };
        "podAntiAffinity" = mkOption {
          description = "Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinity"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node matches the corresponding matchExpressions; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to an update), the system\nmay or may not try to eventually evict the pod from its node.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution"
            )
          );
        };
      };

      config = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "preference" = mkOption {
            description = "A node selector term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference"
            );
          };
          "weight" = mkOption {
            description = "Weight associated with matching the corresponding nodeSelectorTerm, in the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreference" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityPreferredDuringSchedulingIgnoredDuringExecutionPreferenceMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "nodeSelectorTerms" = mkOption {
            description = "Required. A list of node selector terms. The terms are ORed.";
            type = (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms"
              )
            );
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTerms" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "A list of node selector requirements by node's labels.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions"
                )
              )
            );
          };
          "matchFields" = mkOption {
            description = "A list of node selector requirements by node's fields.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchExpressions" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityNodeAffinityRequiredDuringSchedulingIgnoredDuringExecutionNodeSelectorTermsMatchFields" =
      {

        options = {
          "key" = mkOption {
            description = "The label key that the selector applies to.";
            type = types.str;
          };
          "operator" = mkOption {
            description = "Represents a key's relationship to a set of values.\nValid operators are In, NotIn, Exists, DoesNotExist. Gt, and Lt.";
            type = types.str;
          };
          "values" = mkOption {
            description = "An array of string values. If the operator is In or NotIn,\nthe values array must be non-empty. If the operator is Exists or DoesNotExist,\nthe values array must be empty. If the operator is Gt or Lt, the values\narray must have a single element, which will be interpreted as an integer.\nThis array is replaced during a strategic merge patch.";
            type = (types.nullOr (types.listOf types.str));
          };
        };

        config = {
          "values" = mkOverride 1002 null;
        };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and adding\n\"weight\" to the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinity" = {

      options = {
        "preferredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "The scheduler will prefer to schedule pods to nodes that satisfy\nthe anti-affinity expressions specified by this field, but it may choose\na node that violates one or more of the expressions. The node that is\nmost preferred is the one with the greatest sum of weights, i.e.\nfor each node that meets all of the scheduling requirements (resource\nrequest, requiredDuringScheduling anti-affinity expressions, etc.),\ncompute a sum by iterating through the elements of this field and subtracting\n\"weight\" from the sum if the node has pods which matches the corresponding podAffinityTerm; the\nnode(s) with the highest sum are the most preferred.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution"
              )
            )
          );
        };
        "requiredDuringSchedulingIgnoredDuringExecution" = mkOption {
          description = "If the anti-affinity requirements specified by this field are not met at\nscheduling time, the pod will not be scheduled onto the node.\nIf the anti-affinity requirements specified by this field cease to be met\nat some point during pod execution (e.g. due to a pod label update), the\nsystem may or may not try to eventually evict the pod from its node.\nWhen there are multiple elements, the lists of nodes corresponding to each\npodAffinityTerm are intersected, i.e. all terms must be satisfied.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "podAffinityTerm" = mkOption {
            description = "Required. A pod affinity term, associated with the corresponding weight.";
            type = (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm"
            );
          };
          "weight" = mkOption {
            description = "weight associated with matching the corresponding podAffinityTerm,\nin the range 1-100.";
            type = types.int;
          };
        };

        config = { };

      };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTerm" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityPreferredDuringSchedulingIgnoredDuringExecutionPodAffinityTermNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecution" =
      {

        options = {
          "labelSelector" = mkOption {
            description = "A label query over a set of resources, in this case pods.\nIf it's null, this PodAffinityTerm matches with no Pods.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector"
              )
            );
          };
          "matchLabelKeys" = mkOption {
            description = "MatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key in (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both matchLabelKeys and labelSelector.\nAlso, matchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "mismatchLabelKeys" = mkOption {
            description = "MismatchLabelKeys is a set of pod label keys to select which pods will\nbe taken into consideration. The keys are used to lookup values from the\nincoming pod labels, those key-value labels are merged with `labelSelector` as `key notin (value)`\nto select the group of existing pods which pods will be taken into consideration\nfor the incoming pod's pod (anti) affinity. Keys that don't exist in the incoming\npod labels will be ignored. The default value is empty.\nThe same key is forbidden to exist in both mismatchLabelKeys and labelSelector.\nAlso, mismatchLabelKeys cannot be set when labelSelector isn't set.";
            type = (types.nullOr (types.listOf types.str));
          };
          "namespaceSelector" = mkOption {
            description = "A label query over the set of namespaces that the term applies to.\nThe term is applied to the union of the namespaces selected by this field\nand the ones listed in the namespaces field.\nnull selector and null or empty namespaces list means \"this pod's namespace\".\nAn empty selector ({}) matches all namespaces.";
            type = (
              types.nullOr (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector"
              )
            );
          };
          "namespaces" = mkOption {
            description = "namespaces specifies a static list of namespace names that the term applies to.\nThe term is applied to the union of the namespaces listed in this field\nand the ones selected by namespaceSelector.\nnull or empty namespaces list and null namespaceSelector means \"this pod's namespace\".";
            type = (types.nullOr (types.listOf types.str));
          };
          "topologyKey" = mkOption {
            description = "This pod should be co-located (affinity) or not co-located (anti-affinity) with the pods matching\nthe labelSelector in the specified namespaces, where co-located is defined as running on a node\nwhose value of the label with key topologyKey matches that of any node on which any of the\nselected pods is running.\nEmpty topologyKey is not allowed.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionLabelSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelector" =
      {

        options = {
          "matchExpressions" = mkOption {
            description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
            type = (
              types.nullOr (
                types.listOf (
                  submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverAffinityPodAntiAffinityRequiredDuringSchedulingIgnoredDuringExecutionNamespaceSelectorMatchExpressions" =
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverResources" = {

      options = {
        "claims" = mkOption {
          description = "Claims lists the names of resources, defined in spec.resourceClaims,\nthat are used by this container.\n\nThis field depends on the\nDynamicResourceAllocation feature gate.\n\nThis field is immutable. It can only be set for containers.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverResourcesClaims"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverResourcesClaims" = {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContext" = {

      options = {
        "appArmorProfile" = mkOption {
          description = "appArmorProfile is the AppArmor options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContextAppArmorProfile"
            )
          );
        };
        "fsGroup" = mkOption {
          description = "A special supplemental group that applies to all containers in a pod.\nSome volume types allow the Kubelet to change the ownership of that volume\nto be owned by the pod:\n\n1. The owning GID will be the FSGroup\n2. The setgid bit is set (new files created in the volume will be owned by FSGroup)\n3. The permission bits are OR'd with rw-rw----\n\nIf unset, the Kubelet will not modify the ownership and permissions of any volume.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "fsGroupChangePolicy" = mkOption {
          description = "fsGroupChangePolicy defines behavior of changing ownership and permission of the volume\nbefore being exposed inside Pod. This field will only apply to\nvolume types which support fsGroup based ownership(and permissions).\nIt will have no effect on ephemeral volume types such as: secret, configmaps\nand emptydir.\nValid values are \"OnRootMismatch\" and \"Always\". If not specified, \"Always\" is used.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "runAsGroup" = mkOption {
          description = "The GID to run the entrypoint of the container process.\nUses runtime default if unset.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "runAsNonRoot" = mkOption {
          description = "Indicates that the container must run as a non-root user.\nIf true, the Kubelet will validate the image at runtime to ensure that it\ndoes not run as UID 0 (root) and fail to start the container if it does.\nIf unset or false, no such validation will be performed.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
          type = (types.nullOr types.bool);
        };
        "runAsUser" = mkOption {
          description = "The UID to run the entrypoint of the container process.\nDefaults to user specified in image metadata if unspecified.\nMay also be set in SecurityContext.  If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence\nfor that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.int);
        };
        "seLinuxChangePolicy" = mkOption {
          description = "seLinuxChangePolicy defines how the container's SELinux label is applied to all volumes used by the Pod.\nIt has no effect on nodes that do not support SELinux or to volumes does not support SELinux.\nValid values are \"MountOption\" and \"Recursive\".\n\n\"Recursive\" means relabeling of all files on all Pod volumes by the container runtime.\nThis may be slow for large volumes, but allows mixing privileged and unprivileged Pods sharing the same volume on the same node.\n\n\"MountOption\" mounts all eligible Pod volumes with `-o context` mount option.\nThis requires all Pods that share the same volume to use the same SELinux label.\nIt is not possible to share the same volume among privileged and unprivileged Pods.\nEligible volumes are in-tree FibreChannel and iSCSI volumes, and all CSI volumes\nwhose CSI driver announces SELinux support by setting spec.seLinuxMount: true in their\nCSIDriver instance. Other volumes are always re-labelled recursively.\n\"MountOption\" value is allowed only when SELinuxMount feature gate is enabled.\n\nIf not specified and SELinuxMount feature gate is enabled, \"MountOption\" is used.\nIf not specified and SELinuxMount feature gate is disabled, \"MountOption\" is used for ReadWriteOncePod volumes\nand \"Recursive\" for all other volumes.\n\nThis field affects only Pods that have SELinux label set, either in PodSecurityContext or in SecurityContext of all containers.\n\nAll Pods that use the same volume should use the same seLinuxChangePolicy, otherwise some pods can get stuck in ContainerCreating state.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "seLinuxOptions" = mkOption {
          description = "The SELinux context to be applied to all containers.\nIf unspecified, the container runtime will allocate a random SELinux context for each\ncontainer.  May also be set in SecurityContext.  If set in\nboth SecurityContext and PodSecurityContext, the value specified in SecurityContext\ntakes precedence for that container.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContextSeLinuxOptions"
            )
          );
        };
        "seccompProfile" = mkOption {
          description = "The seccomp options to use by the containers in this pod.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContextSeccompProfile"
            )
          );
        };
        "supplementalGroups" = mkOption {
          description = "A list of groups applied to the first process run in each container, in\naddition to the container's primary GID and fsGroup (if specified).  If\nthe SupplementalGroupsPolicy feature is enabled, the\nsupplementalGroupsPolicy field determines whether these are in addition\nto or instead of any group memberships defined in the container image.\nIf unspecified, no additional groups are added, though group memberships\ndefined in the container image may still be used, depending on the\nsupplementalGroupsPolicy field.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr (types.listOf types.int));
        };
        "supplementalGroupsPolicy" = mkOption {
          description = "Defines how supplemental groups of the first container processes are calculated.\nValid values are \"Merge\" and \"Strict\". If not specified, \"Merge\" is used.\n(Alpha) Using the field requires the SupplementalGroupsPolicy feature gate to be enabled\nand the container runtime must implement support for this feature.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (types.nullOr types.str);
        };
        "sysctls" = mkOption {
          description = "Sysctls hold a list of namespaced sysctls used for the pod. Pods with unsupported\nsysctls (by the container runtime) might fail to launch.\nNote that this field cannot be set when spec.os.name is windows.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey
                "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContextSysctls"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
        "windowsOptions" = mkOption {
          description = "The Windows specific settings applied to all containers.\nIf unspecified, the options within a container's SecurityContext will be used.\nIf set in both SecurityContext and PodSecurityContext, the value specified in SecurityContext takes precedence.\nNote that this field cannot be set when spec.os.name is linux.";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContextWindowsOptions"
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContextAppArmorProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile loaded on the node that should be used.\nThe profile must be preconfigured on the node to work.\nMust match the loaded name of the profile.\nMust be set if and only if type is \"Localhost\".";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of AppArmor profile will be applied.\nValid options are:\n  Localhost - a profile pre-loaded on the node.\n  RuntimeDefault - the container runtime's default profile.\n  Unconfined - no AppArmor enforcement.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContextSeLinuxOptions" = {

      options = {
        "level" = mkOption {
          description = "Level is SELinux level label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "role" = mkOption {
          description = "Role is a SELinux role label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "Type is a SELinux type label that applies to the container.";
          type = (types.nullOr types.str);
        };
        "user" = mkOption {
          description = "User is a SELinux user label that applies to the container.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContextSeccompProfile" = {

      options = {
        "localhostProfile" = mkOption {
          description = "localhostProfile indicates a profile defined in a file on the node should be used.\nThe profile must be preconfigured on the node to work.\nMust be a descending path, relative to the kubelet's configured seccomp profile location.\nMust be set if type is \"Localhost\". Must NOT be set for any other type.";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "type indicates which kind of seccomp profile will be applied.\nValid options are:\n\nLocalhost - a profile defined in a file on the node should be used.\nRuntimeDefault - the container runtime default profile should be used.\nUnconfined - no profile should be applied.";
          type = types.str;
        };
      };

      config = {
        "localhostProfile" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContextSysctls" = {

      options = {
        "name" = mkOption {
          description = "Name of a property to set";
          type = types.str;
        };
        "value" = mkOption {
          description = "Value of a property to set";
          type = types.str;
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverSecurityContextWindowsOptions" = {

      options = {
        "gmsaCredentialSpec" = mkOption {
          description = "GMSACredentialSpec is where the GMSA admission webhook\n(https://github.com/kubernetes-sigs/windows-gmsa) inlines the contents of the\nGMSA credential spec named by the GMSACredentialSpecName field.";
          type = (types.nullOr types.str);
        };
        "gmsaCredentialSpecName" = mkOption {
          description = "GMSACredentialSpecName is the name of the GMSA credential spec to use.";
          type = (types.nullOr types.str);
        };
        "hostProcess" = mkOption {
          description = "HostProcess determines if a container should be run as a 'Host Process' container.\nAll of a Pod's containers must have the same effective HostProcess value\n(it is not allowed to have a mix of HostProcess containers and non-HostProcess containers).\nIn addition, if HostProcess is true then HostNetwork must also be set to true.";
          type = (types.nullOr types.bool);
        };
        "runAsUserName" = mkOption {
          description = "The UserName in Windows to run the entrypoint of the container process.\nDefaults to the user specified in image metadata if unspecified.\nMay also be set in PodSecurityContext. If set in both SecurityContext and\nPodSecurityContext, the value specified in SecurityContext takes precedence.";
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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumes" = {

      options = {
        "mountPath" = mkOption {
          description = "Path to give the volume when mounting under /mnt in the mover job pod.\nFor example if mountPath is 'my-pvc' then this moverVolume will be mounted in the mover pod\nat /mnt/my-pvc";
          type = types.str;
        };
        "volumeSource" = mkOption {
          description = "volumeSource represents the secret or PersistentVolumeClaim that should be mounted to the mover pod.";
          type = (
            submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumesVolumeSource"
          );
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumesVolumeSource" = {

      options = {
        "nfs" = mkOption {
          description = "nfs represents an NFS mount on the host that shares a pod's lifetime\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#nfs";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumesVolumeSourceNfs"
            )
          );
        };
        "persistentVolumeClaim" = mkOption {
          description = "persistentVolumeClaimVolumeSource represents a reference to a\nPersistentVolumeClaim in the same namespace.\nMore info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims\nnolint:lll";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumesVolumeSourcePersistentVolumeClaim"
            )
          );
        };
        "secret" = mkOption {
          description = "secret represents a secret that should populate this volume.\nMore info: https://kubernetes.io/docs/concepts/storage/volumes#secret";
          type = (
            types.nullOr (
              submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumesVolumeSourceSecret"
            )
          );
        };
      };

      config = {
        "nfs" = mkOverride 1002 null;
        "persistentVolumeClaim" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumesVolumeSourceNfs" = {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumesVolumeSourcePersistentVolumeClaim" =
      {

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
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumesVolumeSourceSecret" = {

      options = {
        "defaultMode" = mkOption {
          description = "defaultMode is Optional: mode bits used to set permissions on created files by default.\nMust be an octal value between 0000 and 0777 or a decimal value between 0 and 511.\nYAML accepts both octal and decimal values, JSON requires decimal values\nfor mode bits. Defaults to 0644.\nDirectories within the path are not affected by this setting.\nThis might be in conflict with other options that affect the file\nmode, like fsGroup, and the result can be other mode bits set.";
          type = (types.nullOr types.int);
        };
        "items" = mkOption {
          description = "items If unspecified, each key-value pair in the Data field of the referenced\nSecret will be projected into the volume as a file whose name is the\nkey and content is the value. If specified, the listed keys will be\nprojected into the specified paths, and unlisted keys will not be\npresent. If a key is specified which is not present in the Secret,\nthe volume setup will error unless it is marked optional. Paths must be\nrelative and may not contain the '..' path or start with '..'.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumesVolumeSourceSecretItems"
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
        "items" = mkOverride 1002 null;
        "optional" = mkOverride 1002 null;
        "secretName" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingMoverVolumesVolumeSourceSecretItems" = {

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
      };

      config = {
        "mode" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecSyncthingPeers" = {

      options = {
        "ID" = mkOption {
          description = "The peer's Syncthing ID.";
          type = types.str;
        };
        "address" = mkOption {
          description = "The peer's address that our Syncthing node will connect to.";
          type = types.str;
        };
        "introducer" = mkOption {
          description = "A flag that determines whether this peer should\nintroduce us to other peers sharing this volume.\nIt is HIGHLY recommended that two Syncthing peers do NOT\nset each other as introducers as you will have a difficult time\ndisconnecting the two.";
          type = types.bool;
        };
      };

      config = { };

    };
    "volsync.backube.v1alpha1.ReplicationSourceSpecTrigger" = {

      options = {
        "manual" = mkOption {
          description = "manual is a string value that schedules a manual trigger.\nOnce a sync completes then status.lastManualSync is set to the same string value.\nA consumer of a manual trigger should set spec.trigger.manual to a known value\nand then wait for lastManualSync to be updated by the operator to the same value,\nwhich means that the manual trigger will then pause and wait for further\nupdates to the trigger.";
          type = (types.nullOr types.str);
        };
        "schedule" = mkOption {
          description = "schedule is a cronspec (https://en.wikipedia.org/wiki/Cron#Overview) that\ncan be used to schedule replication to occur at regular, time-based\nintervals.\nnolint:lll";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "manual" = mkOverride 1002 null;
        "schedule" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceStatus" = {

      options = {
        "conditions" = mkOption {
          description = "conditions represent the latest available observations of the\nsource's state.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceStatusConditions")
            )
          );
        };
        "external" = mkOption {
          description = "external contains provider-specific status information. For more details,\nplease see the documentation of the specific replication provider being\nused.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "lastManualSync" = mkOption {
          description = "lastManualSync is set to the last spec.trigger.manual when the manual sync is done.";
          type = (types.nullOr types.str);
        };
        "lastSyncDuration" = mkOption {
          description = "lastSyncDuration is the amount of time required to send the most recent\nupdate.";
          type = (types.nullOr types.str);
        };
        "lastSyncStartTime" = mkOption {
          description = "lastSyncStartTime is the time the most recent synchronization started.";
          type = (types.nullOr types.str);
        };
        "lastSyncTime" = mkOption {
          description = "lastSyncTime is the time of the most recent successful synchronization.";
          type = (types.nullOr types.str);
        };
        "latestMoverStatus" = mkOption {
          description = "Logs/Summary from latest mover job";
          type = (
            types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceStatusLatestMoverStatus")
          );
        };
        "nextSyncTime" = mkOption {
          description = "nextSyncTime is the time when the next volume synchronization is\nscheduled to start (for schedule-based synchronization).";
          type = (types.nullOr types.str);
        };
        "restic" = mkOption {
          description = "restic contains status information for Restic-based replication.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceStatusRestic"));
        };
        "rsync" = mkOption {
          description = "rsync contains status information for Rsync-based replication.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceStatusRsync"));
        };
        "rsyncTLS" = mkOption {
          description = "rsyncTLS contains status information for Rsync-based replication over TLS.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceStatusRsyncTLS"));
        };
        "syncthing" = mkOption {
          description = "contains status information when Syncthing-based replication is used.";
          type = (types.nullOr (submoduleOf "volsync.backube.v1alpha1.ReplicationSourceStatusSyncthing"));
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "external" = mkOverride 1002 null;
        "lastManualSync" = mkOverride 1002 null;
        "lastSyncDuration" = mkOverride 1002 null;
        "lastSyncStartTime" = mkOverride 1002 null;
        "lastSyncTime" = mkOverride 1002 null;
        "latestMoverStatus" = mkOverride 1002 null;
        "nextSyncTime" = mkOverride 1002 null;
        "restic" = mkOverride 1002 null;
        "rsync" = mkOverride 1002 null;
        "rsyncTLS" = mkOverride 1002 null;
        "syncthing" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceStatusConditions" = {

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
    "volsync.backube.v1alpha1.ReplicationSourceStatusLatestMoverStatus" = {

      options = {
        "logs" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "result" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "logs" = mkOverride 1002 null;
        "result" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceStatusRestic" = {

      options = {
        "lastPruned" = mkOption {
          description = "lastPruned in the object holding the time of last pruned";
          type = (types.nullOr types.str);
        };
        "lastUnlocked" = mkOption {
          description = "lastUnlocked is set to the last spec.restic.unlock when a sync is done that unlocks the\nrestic repository.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastPruned" = mkOverride 1002 null;
        "lastUnlocked" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceStatusRsync" = {

      options = {
        "address" = mkOption {
          description = "address is the address to connect to for incoming SSH replication\nconnections.";
          type = (types.nullOr types.str);
        };
        "port" = mkOption {
          description = "port is the SSH port to connect to for incoming SSH replication\nconnections.";
          type = (types.nullOr types.int);
        };
        "sshKeys" = mkOption {
          description = "sshKeys is the name of a Secret that contains the SSH keys to be used for\nauthentication. If not provided in .spec.rsync.sshKeys, SSH keys will be\ngenerated and the appropriate keys for the remote side will be placed\nhere.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "address" = mkOverride 1002 null;
        "port" = mkOverride 1002 null;
        "sshKeys" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceStatusRsyncTLS" = {

      options = {
        "keySecret" = mkOption {
          description = "keySecret is the name of a Secret that contains the TLS pre-shared key to\nbe used for authentication. If not provided in .spec.rsyncTLS.keySecret,\nthe key Secret will be generated and named here.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "keySecret" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceStatusSyncthing" = {

      options = {
        "ID" = mkOption {
          description = "Device ID of the current syncthing device";
          type = (types.nullOr types.str);
        };
        "address" = mkOption {
          description = "Service address where Syncthing is exposed to the rest of the world";
          type = (types.nullOr types.str);
        };
        "peers" = mkOption {
          description = "List of the Syncthing nodes we are currently connected to.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "volsync.backube.v1alpha1.ReplicationSourceStatusSyncthingPeers"
                "name"
                [ ]
            )
          );
          apply = attrsToList;
        };
      };

      config = {
        "ID" = mkOverride 1002 null;
        "address" = mkOverride 1002 null;
        "peers" = mkOverride 1002 null;
      };

    };
    "volsync.backube.v1alpha1.ReplicationSourceStatusSyncthingPeers" = {

      options = {
        "ID" = mkOption {
          description = "ID Is the peer's Syncthing ID.";
          type = types.str;
        };
        "address" = mkOption {
          description = "The address of the Syncthing peer.";
          type = types.str;
        };
        "connected" = mkOption {
          description = "Flag indicating whether peer is currently connected.";
          type = types.bool;
        };
        "introducedBy" = mkOption {
          description = "The ID of the Syncthing peer that this one was introduced by.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "A friendly name to associate the given device.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "introducedBy" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
      };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "volsync.backube"."v1alpha1"."ReplicationDestination" = mkOption {
        description = "A ReplicationDestination is a VolSync resource that you can use to define the destination of a VolSync replication\nor synchronization.";
        type = (
          types.attrsOf (
            submoduleForDefinition "volsync.backube.v1alpha1.ReplicationDestination" "replicationdestinations"
              "ReplicationDestination"
              "volsync.backube"
              "v1alpha1"
          )
        );
        default = { };
      };
      "volsync.backube"."v1alpha1"."ReplicationSource" = mkOption {
        description = "A ReplicationSource is a VolSync resource that you can use to define the source PVC and replication mover type,\nenabling you to replicate or synchronize PVC data to a remote location.";
        type = (
          types.attrsOf (
            submoduleForDefinition "volsync.backube.v1alpha1.ReplicationSource" "replicationsources"
              "ReplicationSource"
              "volsync.backube"
              "v1alpha1"
          )
        );
        default = { };
      };

    }
    // {
      "replicationDestinations" = mkOption {
        description = "A ReplicationDestination is a VolSync resource that you can use to define the destination of a VolSync replication\nor synchronization.";
        type = (
          types.attrsOf (
            submoduleForDefinition "volsync.backube.v1alpha1.ReplicationDestination" "replicationdestinations"
              "ReplicationDestination"
              "volsync.backube"
              "v1alpha1"
          )
        );
        default = { };
      };
      "replicationSources" = mkOption {
        description = "A ReplicationSource is a VolSync resource that you can use to define the source PVC and replication mover type,\nenabling you to replicate or synchronize PVC data to a remote location.";
        type = (
          types.attrsOf (
            submoduleForDefinition "volsync.backube.v1alpha1.ReplicationSource" "replicationsources"
              "ReplicationSource"
              "volsync.backube"
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
        name = "replicationdestinations";
        group = "volsync.backube";
        version = "v1alpha1";
        kind = "ReplicationDestination";
        attrName = "replicationDestinations";
      }
      {
        name = "replicationsources";
        group = "volsync.backube";
        version = "v1alpha1";
        kind = "ReplicationSource";
        attrName = "replicationSources";
      }
    ];

    resources = {
      "volsync.backube"."v1alpha1"."ReplicationDestination" =
        mkAliasDefinitions
          options.resources."replicationDestinations";
      "volsync.backube"."v1alpha1"."ReplicationSource" =
        mkAliasDefinitions
          options.resources."replicationSources";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "volsync.backube";
        version = "v1alpha1";
        kind = "ReplicationDestination";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "volsync.backube";
        version = "v1alpha1";
        kind = "ReplicationSource";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
