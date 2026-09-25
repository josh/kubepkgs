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
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshot" = {

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
          description = "Spec defines the desired characteristics of a group snapshot requested by a user.\nRequired.";
          type = (submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotSpec");
        };
        "status" = mkOption {
          description = "Status represents the current information of a group snapshot.\nConsumers must verify binding between VolumeGroupSnapshot and\nVolumeGroupSnapshotContent objects is successful (by validating that both\nVolumeGroupSnapshot and VolumeGroupSnapshotContent point to each other) before\nusing this object.";
          type = (types.nullOr (submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotClass" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "deletionPolicy" = mkOption {
          description = "DeletionPolicy determines whether a VolumeGroupSnapshotContent created\nthrough the VolumeGroupSnapshotClass should be deleted when its bound\nVolumeGroupSnapshot is deleted.\nSupported values are \"Retain\" and \"Delete\".\n\"Retain\" means that the VolumeGroupSnapshotContent and its physical group\nsnapshot on underlying storage system are kept.\n\"Delete\" means that the VolumeGroupSnapshotContent and its physical group\nsnapshot on underlying storage system are deleted.\nRequired.";
          type = (
            types.enum [
              "Delete"
              "Retain"
            ]
          );
        };
        "driver" = mkOption {
          description = "Driver is the name of the storage driver expected to handle this VolumeGroupSnapshotClass.\nRequired.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "parameters" = mkOption {
          description = "Parameters is a key-value map with storage driver specific parameters for\ncreating group snapshots.\nThese values are opaque to Kubernetes and are passed directly to the driver.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "parameters" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContent" = {

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
          description = "Spec defines properties of a VolumeGroupSnapshotContent created by the underlying storage system.\nRequired.";
          type = (submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentSpec");
        };
        "status" = mkOption {
          description = "status represents the current information of a group snapshot.";
          type = (
            types.nullOr (submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentStatus")
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
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentSpec" = {

      options = {
        "deletionPolicy" = mkOption {
          description = "DeletionPolicy determines whether this VolumeGroupSnapshotContent and the\nphysical group snapshot on the underlying storage system should be deleted\nwhen the bound VolumeGroupSnapshot is deleted.\nSupported values are \"Retain\" and \"Delete\".\n\"Retain\" means that the VolumeGroupSnapshotContent and its physical group\nsnapshot on underlying storage system are kept.\n\"Delete\" means that the VolumeGroupSnapshotContent and its physical group\nsnapshot on underlying storage system are deleted.\nFor dynamically provisioned group snapshots, this field will automatically\nbe filled in by the CSI snapshotter sidecar with the \"DeletionPolicy\" field\ndefined in the corresponding VolumeGroupSnapshotClass.\nFor pre-existing snapshots, users MUST specify this field when creating the\nVolumeGroupSnapshotContent object.\nRequired.";
          type = (
            types.enum [
              "Delete"
              "Retain"
            ]
          );
        };
        "driver" = mkOption {
          description = "Driver is the name of the CSI driver used to create the physical group snapshot on\nthe underlying storage system.\nThis MUST be the same as the name returned by the CSI GetPluginName() call for\nthat driver.\nRequired.";
          type = types.str;
        };
        "source" = mkOption {
          description = "Source specifies whether the snapshot is (or should be) dynamically provisioned\nor already exists, and just requires a Kubernetes object representation.\nThis field is immutable after creation.\nRequired.";
          type = (submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentSpecSource");
        };
        "volumeGroupSnapshotClassName" = mkOption {
          description = "VolumeGroupSnapshotClassName is the name of the VolumeGroupSnapshotClass from\nwhich this group snapshot was (or will be) created.\nNote that after provisioning, the VolumeGroupSnapshotClass may be deleted or\nrecreated with different set of values, and as such, should not be referenced\npost-snapshot creation.\nFor dynamic provisioning, this field must be set.\nThis field may be unset for pre-provisioned snapshots.";
          type = (types.nullOr types.str);
        };
        "volumeGroupSnapshotRef" = mkOption {
          description = "VolumeGroupSnapshotRef specifies the VolumeGroupSnapshot object to which this\nVolumeGroupSnapshotContent object is bound.\nVolumeGroupSnapshot.Spec.VolumeGroupSnapshotContentName field must reference to\nthis VolumeGroupSnapshotContent's name for the bidirectional binding to be valid.\nFor a pre-existing VolumeGroupSnapshotContent object, name and namespace of the\nVolumeGroupSnapshot object MUST be provided for binding to happen.\nThis field is immutable after creation.\nRequired.";
          type = (
            submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentSpecVolumeGroupSnapshotRef"
          );
        };
      };

      config = {
        "volumeGroupSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentSpecSource" = {

      options = {
        "groupSnapshotHandles" = mkOption {
          description = "GroupSnapshotHandles specifies the CSI \"group_snapshot_id\" of a pre-existing\ngroup snapshot and a list of CSI \"snapshot_id\" of pre-existing snapshots\non the underlying storage system for which a Kubernetes object\nrepresentation was (or should be) created.\nThis field is immutable.";
          type = (
            types.nullOr (
              submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentSpecSourceGroupSnapshotHandles"
            )
          );
        };
        "volumeHandles" = mkOption {
          description = "VolumeHandles is a list of volume handles on the backend to be snapshotted\ntogether. It is specified for dynamic provisioning of the VolumeGroupSnapshot.\nThis field is immutable.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "groupSnapshotHandles" = mkOverride 1002 null;
        "volumeHandles" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentSpecSourceGroupSnapshotHandles" = {

      options = {
        "volumeGroupSnapshotHandle" = mkOption {
          description = "VolumeGroupSnapshotHandle specifies the CSI \"group_snapshot_id\" of a pre-existing\ngroup snapshot on the underlying storage system for which a Kubernetes object\nrepresentation was (or should be) created.\nThis field is immutable.\nRequired.";
          type = types.str;
        };
        "volumeSnapshotHandles" = mkOption {
          description = "VolumeSnapshotHandles is a list of CSI \"snapshot_id\" of pre-existing\nsnapshots on the underlying storage system for which Kubernetes objects\nrepresentation were (or should be) created.\nThis field is immutable.\nRequired.";
          type = (types.listOf types.str);
        };
      };

      config = { };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentSpecVolumeGroupSnapshotRef" = {

      options = {
        "apiVersion" = mkOption {
          description = "API version of the referent.";
          type = (types.nullOr types.str);
        };
        "fieldPath" = mkOption {
          description = "If referring to a piece of an object instead of an entire object, this string\nshould contain a valid JSON/Go field access statement, such as desiredState.manifest.containers[2].\nFor example, if the object reference is to a container within a pod, this would take on a value like:\n\"spec.containers{name}\" (where \"name\" refers to the name of the container that triggered\nthe event) or if no container name is specified \"spec.containers[2]\" (container with\nindex 2 in this pod). This syntax is chosen only to have some well-defined way of\nreferencing a part of an object.\nTODO: this design is not final and this field is subject to change in the future.";
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
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentStatus" = {

      options = {
        "creationTime" = mkOption {
          description = "CreationTime is the timestamp when the point-in-time group snapshot is taken\nby the underlying storage system.\nIf not specified, it indicates the creation time is unknown.\nIf not specified, it means the readiness of a group snapshot is unknown.\nThis field is the source for the CreationTime field in VolumeGroupSnapshotStatus";
          type = (types.nullOr types.str);
        };
        "error" = mkOption {
          description = "Error is the last observed error during group snapshot creation, if any.\nUpon success after retry, this error field will be cleared.";
          type = (
            types.nullOr (submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentStatusError")
          );
        };
        "readyToUse" = mkOption {
          description = "ReadyToUse indicates if all the individual snapshots in the group are ready to be\nused to restore a group of volumes.\nReadyToUse becomes true when ReadyToUse of all individual snapshots become true.";
          type = (types.nullOr types.bool);
        };
        "volumeGroupSnapshotHandle" = mkOption {
          description = "VolumeGroupSnapshotHandle is a unique id returned by the CSI driver\nto identify the VolumeGroupSnapshot on the storage system.\nIf a storage system does not provide such an id, the\nCSI driver can choose to return the VolumeGroupSnapshot name.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotInfoList" = mkOption {
          description = "This field is introduced in v1beta2\nIt is replacing VolumeSnapshotHandlePairList\nVolumeSnapshotInfoList is a list of snapshot information returned by\nby the CSI driver to identify snapshots on the storage system.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentStatusVolumeSnapshotInfoList"
              )
            )
          );
        };
      };

      config = {
        "creationTime" = mkOverride 1002 null;
        "error" = mkOverride 1002 null;
        "readyToUse" = mkOverride 1002 null;
        "volumeGroupSnapshotHandle" = mkOverride 1002 null;
        "volumeSnapshotInfoList" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentStatusError" = {

      options = {
        "message" = mkOption {
          description = "message is a string detailing the encountered error during snapshot\ncreation if specified.\nNOTE: message may be logged, and it should not contain sensitive\ninformation.";
          type = (types.nullOr types.str);
        };
        "time" = mkOption {
          description = "time is the timestamp when the error was encountered.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "message" = mkOverride 1002 null;
        "time" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContentStatusVolumeSnapshotInfoList" = {

      options = {
        "creationTime" = mkOption {
          description = "creationTime is the timestamp when the point-in-time snapshot is taken\nby the underlying storage system.";
          type = (types.nullOr types.int);
        };
        "readyToUse" = mkOption {
          description = "ReadyToUse indicates if the snapshot is ready to be used to restore a volume.";
          type = (types.nullOr types.bool);
        };
        "restoreSize" = mkOption {
          description = "RestoreSize represents the minimum size of volume required to create a volume\nfrom this snapshot.";
          type = (types.nullOr types.int);
        };
        "snapshotHandle" = mkOption {
          description = "SnapshotHandle is the CSI \"snapshot_id\" of this snapshot on the underlying storage system.";
          type = (types.nullOr types.str);
        };
        "volumeHandle" = mkOption {
          description = "VolumeHandle specifies the CSI \"volume_id\" of the volume from which this snapshot\nwas taken from.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "creationTime" = mkOverride 1002 null;
        "readyToUse" = mkOverride 1002 null;
        "restoreSize" = mkOverride 1002 null;
        "snapshotHandle" = mkOverride 1002 null;
        "volumeHandle" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotSpec" = {

      options = {
        "source" = mkOption {
          description = "Source specifies where a group snapshot will be created from.\nThis field is immutable after creation.\nRequired.";
          type = (submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotSpecSource");
        };
        "volumeGroupSnapshotClassName" = mkOption {
          description = "VolumeGroupSnapshotClassName is the name of the VolumeGroupSnapshotClass\nrequested by the VolumeGroupSnapshot.\nVolumeGroupSnapshotClassName may be left nil to indicate that the default\nclass will be used.\nEmpty string is not allowed for this field.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "volumeGroupSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotSpecSource" = {

      options = {
        "selector" = mkOption {
          description = "Selector is a label query over persistent volume claims that are to be\ngrouped together for snapshotting.\nThis labelSelector will be used to match the label added to a PVC.\nIf the label is added or removed to a volume after a group snapshot\nis created, the existing group snapshots won't be modified.\nOnce a VolumeGroupSnapshotContent is created and the sidecar starts to process\nit, the volume list will not change with retries.";
          type = (
            types.nullOr (submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotSpecSourceSelector")
          );
        };
        "volumeGroupSnapshotContentName" = mkOption {
          description = "VolumeGroupSnapshotContentName specifies the name of a pre-existing VolumeGroupSnapshotContent\nobject representing an existing volume group snapshot.\nThis field should be set if the volume group snapshot already exists and\nonly needs a representation in Kubernetes.\nThis field is immutable.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "selector" = mkOverride 1002 null;
        "volumeGroupSnapshotContentName" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotSpecSourceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotSpecSourceSelectorMatchExpressions"
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
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotSpecSourceSelectorMatchExpressions" = {

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
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotStatus" = {

      options = {
        "boundVolumeGroupSnapshotContentName" = mkOption {
          description = "BoundVolumeGroupSnapshotContentName is the name of the VolumeGroupSnapshotContent\nobject to which this VolumeGroupSnapshot object intends to bind to.\nIf not specified, it indicates that the VolumeGroupSnapshot object has not\nbeen successfully bound to a VolumeGroupSnapshotContent object yet.\nNOTE: To avoid possible security issues, consumers must verify binding between\nVolumeGroupSnapshot and VolumeGroupSnapshotContent objects is successful\n(by validating that both VolumeGroupSnapshot and VolumeGroupSnapshotContent\npoint at each other) before using this object.";
          type = (types.nullOr types.str);
        };
        "creationTime" = mkOption {
          description = "CreationTime is the timestamp when the point-in-time group snapshot is taken\nby the underlying storage system.\nIf not specified, it may indicate that the creation time of the group snapshot\nis unknown.\nThis field is updated based on the CreationTime field in VolumeGroupSnapshotContentStatus";
          type = (types.nullOr types.str);
        };
        "error" = mkOption {
          description = "Error is the last observed error during group snapshot creation, if any.\nThis field could be helpful to upper level controllers (i.e., application\ncontroller) to decide whether they should continue on waiting for the group\nsnapshot to be created based on the type of error reported.\nThe snapshot controller will keep retrying when an error occurs during the\ngroup snapshot creation. Upon success, this error field will be cleared.";
          type = (
            types.nullOr (submoduleOf "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotStatusError")
          );
        };
        "readyToUse" = mkOption {
          description = "ReadyToUse indicates if all the individual snapshots in the group are ready\nto be used to restore a group of volumes.\nReadyToUse becomes true when ReadyToUse of all individual snapshots become true.\nIf not specified, it means the readiness of a group snapshot is unknown.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "boundVolumeGroupSnapshotContentName" = mkOverride 1002 null;
        "creationTime" = mkOverride 1002 null;
        "error" = mkOverride 1002 null;
        "readyToUse" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotStatusError" = {

      options = {
        "message" = mkOption {
          description = "message is a string detailing the encountered error during snapshot\ncreation if specified.\nNOTE: message may be logged, and it should not contain sensitive\ninformation.";
          type = (types.nullOr types.str);
        };
        "time" = mkOption {
          description = "time is the timestamp when the error was encountered.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "message" = mkOverride 1002 null;
        "time" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshot" = {

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
          description = "Spec defines the desired characteristics of a group snapshot requested by a user.\nRequired.";
          type = (submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotSpec");
        };
        "status" = mkOption {
          description = "Status represents the current information of a group snapshot.\nConsumers must verify binding between VolumeGroupSnapshot and\nVolumeGroupSnapshotContent objects is successful (by validating that both\nVolumeGroupSnapshot and VolumeGroupSnapshotContent point to each other) before\nusing this object.";
          type = (
            types.nullOr (submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotStatus")
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
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotClass" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "deletionPolicy" = mkOption {
          description = "DeletionPolicy determines whether a VolumeGroupSnapshotContent created\nthrough the VolumeGroupSnapshotClass should be deleted when its bound\nVolumeGroupSnapshot is deleted.\nSupported values are \"Retain\" and \"Delete\".\n\"Retain\" means that the VolumeGroupSnapshotContent and its physical group\nsnapshot on underlying storage system are kept.\n\"Delete\" means that the VolumeGroupSnapshotContent and its physical group\nsnapshot on underlying storage system are deleted.\nRequired.";
          type = (
            types.enum [
              "Delete"
              "Retain"
            ]
          );
        };
        "driver" = mkOption {
          description = "Driver is the name of the storage driver expected to handle this VolumeGroupSnapshotClass.\nRequired.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "parameters" = mkOption {
          description = "Parameters is a key-value map with storage driver specific parameters for\ncreating group snapshots.\nThese values are opaque to Kubernetes and are passed directly to the driver.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "parameters" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContent" = {

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
          description = "Spec defines properties of a VolumeGroupSnapshotContent created by the underlying storage system.\nRequired.";
          type = (submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentSpec");
        };
        "status" = mkOption {
          description = "status represents the current information of a group snapshot.";
          type = (
            types.nullOr (submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentStatus")
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
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentSpec" = {

      options = {
        "deletionPolicy" = mkOption {
          description = "DeletionPolicy determines whether this VolumeGroupSnapshotContent and the\nphysical group snapshot on the underlying storage system should be deleted\nwhen the bound VolumeGroupSnapshot is deleted.\nSupported values are \"Retain\" and \"Delete\".\n\"Retain\" means that the VolumeGroupSnapshotContent and its physical group\nsnapshot on underlying storage system are kept.\n\"Delete\" means that the VolumeGroupSnapshotContent and its physical group\nsnapshot on underlying storage system are deleted.\nFor dynamically provisioned group snapshots, this field will automatically\nbe filled in by the CSI snapshotter sidecar with the \"DeletionPolicy\" field\ndefined in the corresponding VolumeGroupSnapshotClass.\nFor pre-existing snapshots, users MUST specify this field when creating the\nVolumeGroupSnapshotContent object.\nRequired.";
          type = (
            types.enum [
              "Delete"
              "Retain"
            ]
          );
        };
        "driver" = mkOption {
          description = "Driver is the name of the CSI driver used to create the physical group snapshot on\nthe underlying storage system.\nThis MUST be the same as the name returned by the CSI GetPluginName() call for\nthat driver.\nRequired.";
          type = types.str;
        };
        "source" = mkOption {
          description = "Source specifies whether the snapshot is (or should be) dynamically provisioned\nor already exists, and just requires a Kubernetes object representation.\nThis field is immutable after creation.\nRequired.";
          type = (submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentSpecSource");
        };
        "volumeGroupSnapshotClassName" = mkOption {
          description = "VolumeGroupSnapshotClassName is the name of the VolumeGroupSnapshotClass from\nwhich this group snapshot was (or will be) created.\nNote that after provisioning, the VolumeGroupSnapshotClass may be deleted or\nrecreated with different set of values, and as such, should not be referenced\npost-snapshot creation.\nFor dynamic provisioning, this field must be set.\nThis field may be unset for pre-provisioned snapshots.";
          type = (types.nullOr types.str);
        };
        "volumeGroupSnapshotRef" = mkOption {
          description = "VolumeGroupSnapshotRef specifies the VolumeGroupSnapshot object to which this\nVolumeGroupSnapshotContent object is bound.\nVolumeGroupSnapshot.Spec.VolumeGroupSnapshotContentName field must reference to\nthis VolumeGroupSnapshotContent's name for the bidirectional binding to be valid.\nFor a pre-existing VolumeGroupSnapshotContent object, name and namespace of the\nVolumeGroupSnapshot object MUST be provided for binding to happen.\nThis field is immutable after creation.\nRequired.";
          type = (
            submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentSpecVolumeGroupSnapshotRef"
          );
        };
      };

      config = {
        "volumeGroupSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentSpecSource" = {

      options = {
        "groupSnapshotHandles" = mkOption {
          description = "GroupSnapshotHandles specifies the CSI \"group_snapshot_id\" of a pre-existing\ngroup snapshot and a list of CSI \"snapshot_id\" of pre-existing snapshots\non the underlying storage system for which a Kubernetes object\nrepresentation was (or should be) created.\nThis field is immutable.";
          type = (
            types.nullOr (
              submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentSpecSourceGroupSnapshotHandles"
            )
          );
        };
        "volumeHandles" = mkOption {
          description = "VolumeHandles is a list of volume handles on the backend to be snapshotted\ntogether. It is specified for dynamic provisioning of the VolumeGroupSnapshot.\nThis field is immutable.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "groupSnapshotHandles" = mkOverride 1002 null;
        "volumeHandles" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentSpecSourceGroupSnapshotHandles" = {

      options = {
        "volumeGroupSnapshotHandle" = mkOption {
          description = "VolumeGroupSnapshotHandle specifies the CSI \"group_snapshot_id\" of a pre-existing\ngroup snapshot on the underlying storage system for which a Kubernetes object\nrepresentation was (or should be) created.\nThis field is immutable.\nRequired.";
          type = types.str;
        };
        "volumeSnapshotHandles" = mkOption {
          description = "VolumeSnapshotHandles is a list of CSI \"snapshot_id\" of pre-existing\nsnapshots on the underlying storage system for which Kubernetes objects\nrepresentation were (or should be) created.\nThis field is immutable.\nRequired.";
          type = (types.listOf types.str);
        };
      };

      config = { };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentSpecVolumeGroupSnapshotRef" = {

      options = {
        "apiVersion" = mkOption {
          description = "API version of the referent.";
          type = (types.nullOr types.str);
        };
        "fieldPath" = mkOption {
          description = "If referring to a piece of an object instead of an entire object, this string\nshould contain a valid JSON/Go field access statement, such as desiredState.manifest.containers[2].\nFor example, if the object reference is to a container within a pod, this would take on a value like:\n\"spec.containers{name}\" (where \"name\" refers to the name of the container that triggered\nthe event) or if no container name is specified \"spec.containers[2]\" (container with\nindex 2 in this pod). This syntax is chosen only to have some well-defined way of\nreferencing a part of an object.\nTODO: this design is not final and this field is subject to change in the future.";
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
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentStatus" = {

      options = {
        "creationTime" = mkOption {
          description = "CreationTime is the timestamp when the point-in-time group snapshot is taken\nby the underlying storage system.\nIf not specified, it indicates the creation time is unknown.\nIf not specified, it means the readiness of a group snapshot is unknown.\nThis field is the source for the CreationTime field in VolumeGroupSnapshotStatus";
          type = (types.nullOr types.str);
        };
        "error" = mkOption {
          description = "Error is the last observed error during group snapshot creation, if any.\nUpon success after retry, this error field will be cleared.";
          type = (
            types.nullOr (
              submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentStatusError"
            )
          );
        };
        "readyToUse" = mkOption {
          description = "ReadyToUse indicates if all the individual snapshots in the group are ready to be\nused to restore a group of volumes.\nReadyToUse becomes true when ReadyToUse of all individual snapshots become true.";
          type = (types.nullOr types.bool);
        };
        "volumeGroupSnapshotHandle" = mkOption {
          description = "VolumeGroupSnapshotHandle is a unique id returned by the CSI driver\nto identify the VolumeGroupSnapshot on the storage system.\nIf a storage system does not provide such an id, the\nCSI driver can choose to return the VolumeGroupSnapshot name.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotInfoList" = mkOption {
          description = "This field is introduced in v1beta2\nIt is replacing VolumeSnapshotHandlePairList\nVolumeSnapshotInfoList is a list of snapshot information returned by\nby the CSI driver to identify snapshots on the storage system.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentStatusVolumeSnapshotInfoList"
              )
            )
          );
        };
      };

      config = {
        "creationTime" = mkOverride 1002 null;
        "error" = mkOverride 1002 null;
        "readyToUse" = mkOverride 1002 null;
        "volumeGroupSnapshotHandle" = mkOverride 1002 null;
        "volumeSnapshotInfoList" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentStatusError" = {

      options = {
        "message" = mkOption {
          description = "message is a string detailing the encountered error during snapshot\ncreation if specified.\nNOTE: message may be logged, and it should not contain sensitive\ninformation.";
          type = (types.nullOr types.str);
        };
        "time" = mkOption {
          description = "time is the timestamp when the error was encountered.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "message" = mkOverride 1002 null;
        "time" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContentStatusVolumeSnapshotInfoList" = {

      options = {
        "creationTime" = mkOption {
          description = "creationTime is the timestamp when the point-in-time snapshot is taken\nby the underlying storage system.";
          type = (types.nullOr types.int);
        };
        "readyToUse" = mkOption {
          description = "ReadyToUse indicates if the snapshot is ready to be used to restore a volume.";
          type = (types.nullOr types.bool);
        };
        "restoreSize" = mkOption {
          description = "RestoreSize represents the minimum size of volume required to create a volume\nfrom this snapshot.";
          type = (types.nullOr types.int);
        };
        "snapshotHandle" = mkOption {
          description = "SnapshotHandle is the CSI \"snapshot_id\" of this snapshot on the underlying storage system.";
          type = (types.nullOr types.str);
        };
        "volumeHandle" = mkOption {
          description = "VolumeHandle specifies the CSI \"volume_id\" of the volume from which this snapshot\nwas taken from.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "creationTime" = mkOverride 1002 null;
        "readyToUse" = mkOverride 1002 null;
        "restoreSize" = mkOverride 1002 null;
        "snapshotHandle" = mkOverride 1002 null;
        "volumeHandle" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotSpec" = {

      options = {
        "source" = mkOption {
          description = "Source specifies where a group snapshot will be created from.\nThis field is immutable after creation.\nRequired.";
          type = (submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotSpecSource");
        };
        "volumeGroupSnapshotClassName" = mkOption {
          description = "VolumeGroupSnapshotClassName is the name of the VolumeGroupSnapshotClass\nrequested by the VolumeGroupSnapshot.\nVolumeGroupSnapshotClassName may be left nil to indicate that the default\nclass will be used.\nEmpty string is not allowed for this field.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "volumeGroupSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotSpecSource" = {

      options = {
        "selector" = mkOption {
          description = "Selector is a label query over persistent volume claims that are to be\ngrouped together for snapshotting.\nThis labelSelector will be used to match the label added to a PVC.\nIf the label is added or removed to a volume after a group snapshot\nis created, the existing group snapshots won't be modified.\nOnce a VolumeGroupSnapshotContent is created and the sidecar starts to process\nit, the volume list will not change with retries.";
          type = (
            types.nullOr (
              submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotSpecSourceSelector"
            )
          );
        };
        "volumeGroupSnapshotContentName" = mkOption {
          description = "VolumeGroupSnapshotContentName specifies the name of a pre-existing VolumeGroupSnapshotContent\nobject representing an existing volume group snapshot.\nThis field should be set if the volume group snapshot already exists and\nonly needs a representation in Kubernetes.\nThis field is immutable.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "selector" = mkOverride 1002 null;
        "volumeGroupSnapshotContentName" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotSpecSourceSelector" = {

      options = {
        "matchExpressions" = mkOption {
          description = "matchExpressions is a list of label selector requirements. The requirements are ANDed.";
          type = (
            types.nullOr (
              types.listOf (
                submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotSpecSourceSelectorMatchExpressions"
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
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotSpecSourceSelectorMatchExpressions" = {

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
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotStatus" = {

      options = {
        "boundVolumeGroupSnapshotContentName" = mkOption {
          description = "BoundVolumeGroupSnapshotContentName is the name of the VolumeGroupSnapshotContent\nobject to which this VolumeGroupSnapshot object intends to bind to.\nIf not specified, it indicates that the VolumeGroupSnapshot object has not\nbeen successfully bound to a VolumeGroupSnapshotContent object yet.\nNOTE: To avoid possible security issues, consumers must verify binding between\nVolumeGroupSnapshot and VolumeGroupSnapshotContent objects is successful\n(by validating that both VolumeGroupSnapshot and VolumeGroupSnapshotContent\npoint at each other) before using this object.";
          type = (types.nullOr types.str);
        };
        "creationTime" = mkOption {
          description = "CreationTime is the timestamp when the point-in-time group snapshot is taken\nby the underlying storage system.\nIf not specified, it may indicate that the creation time of the group snapshot\nis unknown.\nThis field is updated based on the CreationTime field in VolumeGroupSnapshotContentStatus";
          type = (types.nullOr types.str);
        };
        "error" = mkOption {
          description = "Error is the last observed error during group snapshot creation, if any.\nThis field could be helpful to upper level controllers (i.e., application\ncontroller) to decide whether they should continue on waiting for the group\nsnapshot to be created based on the type of error reported.\nThe snapshot controller will keep retrying when an error occurs during the\ngroup snapshot creation. Upon success, this error field will be cleared.";
          type = (
            types.nullOr (submoduleOf "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotStatusError")
          );
        };
        "readyToUse" = mkOption {
          description = "ReadyToUse indicates if all the individual snapshots in the group are ready\nto be used to restore a group of volumes.\nReadyToUse becomes true when ReadyToUse of all individual snapshots become true.\nIf not specified, it means the readiness of a group snapshot is unknown.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "boundVolumeGroupSnapshotContentName" = mkOverride 1002 null;
        "creationTime" = mkOverride 1002 null;
        "error" = mkOverride 1002 null;
        "readyToUse" = mkOverride 1002 null;
      };

    };
    "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotStatusError" = {

      options = {
        "message" = mkOption {
          description = "message is a string detailing the encountered error during snapshot\ncreation if specified.\nNOTE: message may be logged, and it should not contain sensitive\ninformation.";
          type = (types.nullOr types.str);
        };
        "time" = mkOption {
          description = "time is the timestamp when the error was encountered.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "message" = mkOverride 1002 null;
        "time" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshot" = {

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
          description = "spec defines the desired characteristics of a snapshot requested by a user.\nMore info: https://kubernetes.io/docs/concepts/storage/volume-snapshots#volumesnapshots\nRequired.";
          type = (submoduleOf "snapshot.storage.k8s.io.v1.VolumeSnapshotSpec");
        };
        "status" = mkOption {
          description = "status represents the current information of a snapshot.\nConsumers must verify binding between VolumeSnapshot and\nVolumeSnapshotContent objects is successful (by validating that both\nVolumeSnapshot and VolumeSnapshotContent point at each other) before\nusing this object.";
          type = (types.nullOr (submoduleOf "snapshot.storage.k8s.io.v1.VolumeSnapshotStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshotClass" = {

      options = {
        "apiVersion" = mkOption {
          description = "APIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources";
          type = (types.nullOr types.str);
        };
        "deletionPolicy" = mkOption {
          description = "deletionPolicy determines whether a VolumeSnapshotContent created through\nthe VolumeSnapshotClass should be deleted when its bound VolumeSnapshot is deleted.\nSupported values are \"Retain\" and \"Delete\".\n\"Retain\" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are kept.\n\"Delete\" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are deleted.\nRequired.";
          type = (
            types.enum [
              "Delete"
              "Retain"
            ]
          );
        };
        "driver" = mkOption {
          description = "driver is the name of the storage driver that handles this VolumeSnapshotClass.\nRequired.";
          type = types.str;
        };
        "kind" = mkOption {
          description = "Kind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "parameters" = mkOption {
          description = "parameters is a key-value map with storage driver specific parameters for creating snapshots.\nThese values are opaque to Kubernetes.";
          type = (types.nullOr (types.attrsOf types.str));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "parameters" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshotContent" = {

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
          description = "spec defines properties of a VolumeSnapshotContent created by the underlying storage system.\nRequired.";
          type = (submoduleOf "snapshot.storage.k8s.io.v1.VolumeSnapshotContentSpec");
        };
        "status" = mkOption {
          description = "status represents the current information of a snapshot.";
          type = (types.nullOr (submoduleOf "snapshot.storage.k8s.io.v1.VolumeSnapshotContentStatus"));
        };
      };

      config = {
        "apiVersion" = mkOverride 1002 null;
        "kind" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshotContentSpec" = {

      options = {
        "deletionPolicy" = mkOption {
          description = "deletionPolicy determines whether this VolumeSnapshotContent and its physical snapshot on\nthe underlying storage system should be deleted when its bound VolumeSnapshot is deleted.\nSupported values are \"Retain\" and \"Delete\".\n\"Retain\" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are kept.\n\"Delete\" means that the VolumeSnapshotContent and its physical snapshot on underlying storage system are deleted.\nFor dynamically provisioned snapshots, this field will automatically be filled in by the\nCSI snapshotter sidecar with the \"DeletionPolicy\" field defined in the corresponding\nVolumeSnapshotClass.\nFor pre-existing snapshots, users MUST specify this field when creating the\n VolumeSnapshotContent object.\nRequired.";
          type = (
            types.enum [
              "Delete"
              "Retain"
            ]
          );
        };
        "driver" = mkOption {
          description = "driver is the name of the CSI driver used to create the physical snapshot on\nthe underlying storage system.\nThis MUST be the same as the name returned by the CSI GetPluginName() call for\nthat driver.\nRequired.";
          type = types.str;
        };
        "source" = mkOption {
          description = "source specifies whether the snapshot is (or should be) dynamically provisioned\nor already exists, and just requires a Kubernetes object representation.\nThis field is immutable after creation.\nRequired.";
          type = (submoduleOf "snapshot.storage.k8s.io.v1.VolumeSnapshotContentSpecSource");
        };
        "sourceVolumeMode" = mkOption {
          description = "SourceVolumeMode is the mode of the volume whose snapshot is taken.\nCan be either “Filesystem” or “Block”.\nIf not specified, it indicates the source volume's mode is unknown.\nThis field is immutable.\nThis field is an alpha field.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotClassName" = mkOption {
          description = "name of the VolumeSnapshotClass from which this snapshot was (or will be)\ncreated.\nNote that after provisioning, the VolumeSnapshotClass may be deleted or\nrecreated with different set of values, and as such, should not be referenced\npost-snapshot creation.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotRef" = mkOption {
          description = "volumeSnapshotRef specifies the VolumeSnapshot object to which this\nVolumeSnapshotContent object is bound.\nVolumeSnapshot.Spec.VolumeSnapshotContentName field must reference to\nthis VolumeSnapshotContent's name for the bidirectional binding to be valid.\nFor a pre-existing VolumeSnapshotContent object, name and namespace of the\nVolumeSnapshot object MUST be provided for binding to happen.\nThis field is immutable after creation.\nRequired.";
          type = (submoduleOf "snapshot.storage.k8s.io.v1.VolumeSnapshotContentSpecVolumeSnapshotRef");
        };
      };

      config = {
        "sourceVolumeMode" = mkOverride 1002 null;
        "volumeSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshotContentSpecSource" = {

      options = {
        "snapshotHandle" = mkOption {
          description = "snapshotHandle specifies the CSI \"snapshot_id\" of a pre-existing snapshot on\nthe underlying storage system for which a Kubernetes object representation\nwas (or should be) created.\nThis field is immutable.";
          type = (types.nullOr types.str);
        };
        "volumeHandle" = mkOption {
          description = "volumeHandle specifies the CSI \"volume_id\" of the volume from which a snapshot\nshould be dynamically taken from.\nThis field is immutable.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "snapshotHandle" = mkOverride 1002 null;
        "volumeHandle" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshotContentSpecVolumeSnapshotRef" = {

      options = {
        "apiVersion" = mkOption {
          description = "API version of the referent.";
          type = (types.nullOr types.str);
        };
        "fieldPath" = mkOption {
          description = "If referring to a piece of an object instead of an entire object, this string\nshould contain a valid JSON/Go field access statement, such as desiredState.manifest.containers[2].\nFor example, if the object reference is to a container within a pod, this would take on a value like:\n\"spec.containers{name}\" (where \"name\" refers to the name of the container that triggered\nthe event) or if no container name is specified \"spec.containers[2]\" (container with\nindex 2 in this pod). This syntax is chosen only to have some well-defined way of\nreferencing a part of an object.\nTODO: this design is not final and this field is subject to change in the future.";
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
    "snapshot.storage.k8s.io.v1.VolumeSnapshotContentStatus" = {

      options = {
        "creationTime" = mkOption {
          description = "creationTime is the timestamp when the point-in-time snapshot is taken\nby the underlying storage system.\nIn dynamic snapshot creation case, this field will be filled in by the\nCSI snapshotter sidecar with the \"creation_time\" value returned from CSI\n\"CreateSnapshot\" gRPC call.\nFor a pre-existing snapshot, this field will be filled with the \"creation_time\"\nvalue returned from the CSI \"ListSnapshots\" gRPC call if the driver supports it.\nIf not specified, it indicates the creation time is unknown.\nThe format of this field is a Unix nanoseconds time encoded as an int64.\nOn Unix, the command `date +%s%N` returns the current time in nanoseconds\nsince 1970-01-01 00:00:00 UTC.";
          type = (types.nullOr types.int);
        };
        "error" = mkOption {
          description = "error is the last observed error during snapshot creation, if any.\nUpon success after retry, this error field will be cleared.";
          type = (types.nullOr (submoduleOf "snapshot.storage.k8s.io.v1.VolumeSnapshotContentStatusError"));
        };
        "readyToUse" = mkOption {
          description = "readyToUse indicates if a snapshot is ready to be used to restore a volume.\nIn dynamic snapshot creation case, this field will be filled in by the\nCSI snapshotter sidecar with the \"ready_to_use\" value returned from CSI\n\"CreateSnapshot\" gRPC call.\nFor a pre-existing snapshot, this field will be filled with the \"ready_to_use\"\nvalue returned from the CSI \"ListSnapshots\" gRPC call if the driver supports it,\notherwise, this field will be set to \"True\".\nIf not specified, it means the readiness of a snapshot is unknown.";
          type = (types.nullOr types.bool);
        };
        "restoreSize" = mkOption {
          description = "restoreSize represents the complete size of the snapshot in bytes.\nIn dynamic snapshot creation case, this field will be filled in by the\nCSI snapshotter sidecar with the \"size_bytes\" value returned from CSI\n\"CreateSnapshot\" gRPC call.\nFor a pre-existing snapshot, this field will be filled with the \"size_bytes\"\nvalue returned from the CSI \"ListSnapshots\" gRPC call if the driver supports it.\nWhen restoring a volume from this snapshot, the size of the volume MUST NOT\nbe smaller than the restoreSize if it is specified, otherwise the restoration will fail.\nIf not specified, it indicates that the size is unknown.";
          type = (types.nullOr (types.withMinimum 0 types.int));
        };
        "snapshotHandle" = mkOption {
          description = "snapshotHandle is the CSI \"snapshot_id\" of a snapshot on the underlying storage system.\nIf not specified, it indicates that dynamic snapshot creation has either failed\nor it is still in progress.";
          type = (types.nullOr types.str);
        };
        "volumeGroupSnapshotHandle" = mkOption {
          description = "VolumeGroupSnapshotHandle is the CSI \"group_snapshot_id\" of a group snapshot\non the underlying storage system.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "creationTime" = mkOverride 1002 null;
        "error" = mkOverride 1002 null;
        "readyToUse" = mkOverride 1002 null;
        "restoreSize" = mkOverride 1002 null;
        "snapshotHandle" = mkOverride 1002 null;
        "volumeGroupSnapshotHandle" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshotContentStatusError" = {

      options = {
        "message" = mkOption {
          description = "message is a string detailing the encountered error during snapshot\ncreation if specified.\nNOTE: message may be logged, and it should not contain sensitive\ninformation.";
          type = (types.nullOr types.str);
        };
        "time" = mkOption {
          description = "time is the timestamp when the error was encountered.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "message" = mkOverride 1002 null;
        "time" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshotSpec" = {

      options = {
        "source" = mkOption {
          description = "source specifies where a snapshot will be created from.\nThis field is immutable after creation.\nRequired.";
          type = (submoduleOf "snapshot.storage.k8s.io.v1.VolumeSnapshotSpecSource");
        };
        "volumeSnapshotClassName" = mkOption {
          description = "VolumeSnapshotClassName is the name of the VolumeSnapshotClass\nrequested by the VolumeSnapshot.\nVolumeSnapshotClassName may be left nil to indicate that the default\nSnapshotClass should be used.\nA given cluster may have multiple default Volume SnapshotClasses: one\ndefault per CSI Driver. If a VolumeSnapshot does not specify a SnapshotClass,\nVolumeSnapshotSource will be checked to figure out what the associated\nCSI Driver is, and the default VolumeSnapshotClass associated with that\nCSI Driver will be used. If more than one VolumeSnapshotClass exist for\na given CSI Driver and more than one have been marked as default,\nCreateSnapshot will fail and generate an event.\nEmpty string is not allowed for this field.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "volumeSnapshotClassName" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshotSpecSource" = {

      options = {
        "persistentVolumeClaimName" = mkOption {
          description = "persistentVolumeClaimName specifies the name of the PersistentVolumeClaim\nobject representing the volume from which a snapshot should be created.\nThis PVC is assumed to be in the same namespace as the VolumeSnapshot\nobject.\nThis field should be set if the snapshot does not exists, and needs to be\ncreated.\nThis field is immutable.";
          type = (types.nullOr types.str);
        };
        "volumeSnapshotContentName" = mkOption {
          description = "volumeSnapshotContentName specifies the name of a pre-existing VolumeSnapshotContent\nobject representing an existing volume snapshot.\nThis field should be set if the snapshot already exists and only needs a representation in Kubernetes.\nThis field is immutable.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "persistentVolumeClaimName" = mkOverride 1002 null;
        "volumeSnapshotContentName" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshotStatus" = {

      options = {
        "boundVolumeSnapshotContentName" = mkOption {
          description = "boundVolumeSnapshotContentName is the name of the VolumeSnapshotContent\nobject to which this VolumeSnapshot object intends to bind to.\nIf not specified, it indicates that the VolumeSnapshot object has not been\nsuccessfully bound to a VolumeSnapshotContent object yet.\nNOTE: To avoid possible security issues, consumers must verify binding between\nVolumeSnapshot and VolumeSnapshotContent objects is successful (by validating that\nboth VolumeSnapshot and VolumeSnapshotContent point at each other) before using\nthis object.";
          type = (types.nullOr types.str);
        };
        "creationTime" = mkOption {
          description = "creationTime is the timestamp when the point-in-time snapshot is taken\nby the underlying storage system.\nIn dynamic snapshot creation case, this field will be filled in by the\nsnapshot controller with the \"creation_time\" value returned from CSI\n\"CreateSnapshot\" gRPC call.\nFor a pre-existing snapshot, this field will be filled with the \"creation_time\"\nvalue returned from the CSI \"ListSnapshots\" gRPC call if the driver supports it.\nIf not specified, it may indicate that the creation time of the snapshot is unknown.";
          type = (types.nullOr types.str);
        };
        "error" = mkOption {
          description = "error is the last observed error during snapshot creation, if any.\nThis field could be helpful to upper level controllers(i.e., application controller)\nto decide whether they should continue on waiting for the snapshot to be created\nbased on the type of error reported.\nThe snapshot controller will keep retrying when an error occurs during the\nsnapshot creation. Upon success, this error field will be cleared.";
          type = (types.nullOr (submoduleOf "snapshot.storage.k8s.io.v1.VolumeSnapshotStatusError"));
        };
        "readyToUse" = mkOption {
          description = "readyToUse indicates if the snapshot is ready to be used to restore a volume.\nIn dynamic snapshot creation case, this field will be filled in by the\nsnapshot controller with the \"ready_to_use\" value returned from CSI\n\"CreateSnapshot\" gRPC call.\nFor a pre-existing snapshot, this field will be filled with the \"ready_to_use\"\nvalue returned from the CSI \"ListSnapshots\" gRPC call if the driver supports it,\notherwise, this field will be set to \"True\".\nIf not specified, it means the readiness of a snapshot is unknown.";
          type = (types.nullOr types.bool);
        };
        "restoreSize" = mkOption {
          description = "restoreSize represents the minimum size of volume required to create a volume\nfrom this snapshot.\nIn dynamic snapshot creation case, this field will be filled in by the\nsnapshot controller with the \"size_bytes\" value returned from CSI\n\"CreateSnapshot\" gRPC call.\nFor a pre-existing snapshot, this field will be filled with the \"size_bytes\"\nvalue returned from the CSI \"ListSnapshots\" gRPC call if the driver supports it.\nWhen restoring a volume from this snapshot, the size of the volume MUST NOT\nbe smaller than the restoreSize if it is specified, otherwise the restoration will fail.\nIf not specified, it indicates that the size is unknown.";
          type = (types.nullOr types.str);
        };
        "volumeGroupSnapshotName" = mkOption {
          description = "VolumeGroupSnapshotName is the name of the VolumeGroupSnapshot of which this\nVolumeSnapshot is a part of.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "boundVolumeSnapshotContentName" = mkOverride 1002 null;
        "creationTime" = mkOverride 1002 null;
        "error" = mkOverride 1002 null;
        "readyToUse" = mkOverride 1002 null;
        "restoreSize" = mkOverride 1002 null;
        "volumeGroupSnapshotName" = mkOverride 1002 null;
      };

    };
    "snapshot.storage.k8s.io.v1.VolumeSnapshotStatusError" = {

      options = {
        "message" = mkOption {
          description = "message is a string detailing the encountered error during snapshot\ncreation if specified.\nNOTE: message may be logged, and it should not contain sensitive\ninformation.";
          type = (types.nullOr types.str);
        };
        "time" = mkOption {
          description = "time is the timestamp when the error was encountered.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "message" = mkOverride 1002 null;
        "time" = mkOverride 1002 null;
      };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "groupsnapshot.storage.k8s.io"."v1"."VolumeGroupSnapshot" = mkOption {
        description = "VolumeGroupSnapshot is a user's request for creating either a point-in-time\ngroup snapshot or binding to a pre-existing group snapshot.";
        type = (
          types.attrsOf (
            submoduleForDefinition "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshot" "volumegroupsnapshots"
              "VolumeGroupSnapshot"
              "groupsnapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };
      "groupsnapshot.storage.k8s.io"."v1"."VolumeGroupSnapshotClass" = mkOption {
        description = "VolumeGroupSnapshotClass specifies parameters that a underlying storage system\nuses when creating a volume group snapshot. A specific VolumeGroupSnapshotClass\nis used by specifying its name in a VolumeGroupSnapshot object.\nVolumeGroupSnapshotClasses are non-namespaced.";
        type = (
          types.attrsOf (
            submoduleForDefinition "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotClass"
              "volumegroupsnapshotclasses"
              "VolumeGroupSnapshotClass"
              "groupsnapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };
      "groupsnapshot.storage.k8s.io"."v1"."VolumeGroupSnapshotContent" = mkOption {
        description = "VolumeGroupSnapshotContent represents the actual \"on-disk\" group snapshot object\nin the underlying storage system";
        type = (
          types.attrsOf (
            submoduleForDefinition "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContent"
              "volumegroupsnapshotcontents"
              "VolumeGroupSnapshotContent"
              "groupsnapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };
      "groupsnapshot.storage.k8s.io"."v1beta2"."VolumeGroupSnapshot" = mkOption {
        description = "VolumeGroupSnapshot is a user's request for creating either a point-in-time\ngroup snapshot or binding to a pre-existing group snapshot.";
        type = (
          types.attrsOf (
            submoduleForDefinition "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshot"
              "volumegroupsnapshots"
              "VolumeGroupSnapshot"
              "groupsnapshot.storage.k8s.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "groupsnapshot.storage.k8s.io"."v1beta2"."VolumeGroupSnapshotClass" = mkOption {
        description = "VolumeGroupSnapshotClass specifies parameters that a underlying storage system\nuses when creating a volume group snapshot. A specific VolumeGroupSnapshotClass\nis used by specifying its name in a VolumeGroupSnapshot object.\nVolumeGroupSnapshotClasses are non-namespaced.";
        type = (
          types.attrsOf (
            submoduleForDefinition "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotClass"
              "volumegroupsnapshotclasses"
              "VolumeGroupSnapshotClass"
              "groupsnapshot.storage.k8s.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "groupsnapshot.storage.k8s.io"."v1beta2"."VolumeGroupSnapshotContent" = mkOption {
        description = "VolumeGroupSnapshotContent represents the actual \"on-disk\" group snapshot object\nin the underlying storage system";
        type = (
          types.attrsOf (
            submoduleForDefinition "groupsnapshot.storage.k8s.io.v1beta2.VolumeGroupSnapshotContent"
              "volumegroupsnapshotcontents"
              "VolumeGroupSnapshotContent"
              "groupsnapshot.storage.k8s.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "snapshot.storage.k8s.io"."v1"."VolumeSnapshot" = mkOption {
        description = "VolumeSnapshot is a user's request for either creating a point-in-time\nsnapshot of a persistent volume, or binding to a pre-existing snapshot.";
        type = (
          types.attrsOf (
            submoduleForDefinition "snapshot.storage.k8s.io.v1.VolumeSnapshot" "volumesnapshots"
              "VolumeSnapshot"
              "snapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };
      "snapshot.storage.k8s.io"."v1"."VolumeSnapshotClass" = mkOption {
        description = "VolumeSnapshotClass specifies parameters that a underlying storage system uses when\ncreating a volume snapshot. A specific VolumeSnapshotClass is used by specifying its\nname in a VolumeSnapshot object.\nVolumeSnapshotClasses are non-namespaced";
        type = (
          types.attrsOf (
            submoduleForDefinition "snapshot.storage.k8s.io.v1.VolumeSnapshotClass" "volumesnapshotclasses"
              "VolumeSnapshotClass"
              "snapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };
      "snapshot.storage.k8s.io"."v1"."VolumeSnapshotContent" = mkOption {
        description = "VolumeSnapshotContent represents the actual \"on-disk\" snapshot object in the\nunderlying storage system";
        type = (
          types.attrsOf (
            submoduleForDefinition "snapshot.storage.k8s.io.v1.VolumeSnapshotContent" "volumesnapshotcontents"
              "VolumeSnapshotContent"
              "snapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };

    }
    // {
      "volumeGroupSnapshots" = mkOption {
        description = "VolumeGroupSnapshot is a user's request for creating either a point-in-time\ngroup snapshot or binding to a pre-existing group snapshot.";
        type = (
          types.attrsOf (
            submoduleForDefinition "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshot" "volumegroupsnapshots"
              "VolumeGroupSnapshot"
              "groupsnapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };
      "volumeGroupSnapshotClasses" = mkOption {
        description = "VolumeGroupSnapshotClass specifies parameters that a underlying storage system\nuses when creating a volume group snapshot. A specific VolumeGroupSnapshotClass\nis used by specifying its name in a VolumeGroupSnapshot object.\nVolumeGroupSnapshotClasses are non-namespaced.";
        type = (
          types.attrsOf (
            submoduleForDefinition "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotClass"
              "volumegroupsnapshotclasses"
              "VolumeGroupSnapshotClass"
              "groupsnapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };
      "volumeGroupSnapshotContents" = mkOption {
        description = "VolumeGroupSnapshotContent represents the actual \"on-disk\" group snapshot object\nin the underlying storage system";
        type = (
          types.attrsOf (
            submoduleForDefinition "groupsnapshot.storage.k8s.io.v1.VolumeGroupSnapshotContent"
              "volumegroupsnapshotcontents"
              "VolumeGroupSnapshotContent"
              "groupsnapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };
      "volumeSnapshots" = mkOption {
        description = "VolumeSnapshot is a user's request for either creating a point-in-time\nsnapshot of a persistent volume, or binding to a pre-existing snapshot.";
        type = (
          types.attrsOf (
            submoduleForDefinition "snapshot.storage.k8s.io.v1.VolumeSnapshot" "volumesnapshots"
              "VolumeSnapshot"
              "snapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };
      "volumeSnapshotClasses" = mkOption {
        description = "VolumeSnapshotClass specifies parameters that a underlying storage system uses when\ncreating a volume snapshot. A specific VolumeSnapshotClass is used by specifying its\nname in a VolumeSnapshot object.\nVolumeSnapshotClasses are non-namespaced";
        type = (
          types.attrsOf (
            submoduleForDefinition "snapshot.storage.k8s.io.v1.VolumeSnapshotClass" "volumesnapshotclasses"
              "VolumeSnapshotClass"
              "snapshot.storage.k8s.io"
              "v1"
          )
        );
        default = { };
      };
      "volumeSnapshotContents" = mkOption {
        description = "VolumeSnapshotContent represents the actual \"on-disk\" snapshot object in the\nunderlying storage system";
        type = (
          types.attrsOf (
            submoduleForDefinition "snapshot.storage.k8s.io.v1.VolumeSnapshotContent" "volumesnapshotcontents"
              "VolumeSnapshotContent"
              "snapshot.storage.k8s.io"
              "v1"
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
        name = "volumegroupsnapshots";
        group = "groupsnapshot.storage.k8s.io";
        version = "v1";
        kind = "VolumeGroupSnapshot";
        attrName = "volumeGroupSnapshots";
      }
      {
        name = "volumegroupsnapshotclasses";
        group = "groupsnapshot.storage.k8s.io";
        version = "v1";
        kind = "VolumeGroupSnapshotClass";
        attrName = "volumeGroupSnapshotClasses";
      }
      {
        name = "volumegroupsnapshotcontents";
        group = "groupsnapshot.storage.k8s.io";
        version = "v1";
        kind = "VolumeGroupSnapshotContent";
        attrName = "volumeGroupSnapshotContents";
      }
      {
        name = "volumegroupsnapshots";
        group = "groupsnapshot.storage.k8s.io";
        version = "v1beta2";
        kind = "VolumeGroupSnapshot";
        attrName = "volumeGroupSnapshots";
      }
      {
        name = "volumegroupsnapshotclasses";
        group = "groupsnapshot.storage.k8s.io";
        version = "v1beta2";
        kind = "VolumeGroupSnapshotClass";
        attrName = "volumeGroupSnapshotClasses";
      }
      {
        name = "volumegroupsnapshotcontents";
        group = "groupsnapshot.storage.k8s.io";
        version = "v1beta2";
        kind = "VolumeGroupSnapshotContent";
        attrName = "volumeGroupSnapshotContents";
      }
      {
        name = "volumesnapshots";
        group = "snapshot.storage.k8s.io";
        version = "v1";
        kind = "VolumeSnapshot";
        attrName = "volumeSnapshots";
      }
      {
        name = "volumesnapshotclasses";
        group = "snapshot.storage.k8s.io";
        version = "v1";
        kind = "VolumeSnapshotClass";
        attrName = "volumeSnapshotClasses";
      }
      {
        name = "volumesnapshotcontents";
        group = "snapshot.storage.k8s.io";
        version = "v1";
        kind = "VolumeSnapshotContent";
        attrName = "volumeSnapshotContents";
      }
    ];

    resources = {
      "groupsnapshot.storage.k8s.io"."v1"."VolumeGroupSnapshot" =
        mkAliasDefinitions
          options.resources."volumeGroupSnapshots";
      "groupsnapshot.storage.k8s.io"."v1"."VolumeGroupSnapshotClass" =
        mkAliasDefinitions
          options.resources."volumeGroupSnapshotClasses";
      "groupsnapshot.storage.k8s.io"."v1"."VolumeGroupSnapshotContent" =
        mkAliasDefinitions
          options.resources."volumeGroupSnapshotContents";
      "snapshot.storage.k8s.io"."v1"."VolumeSnapshot" =
        mkAliasDefinitions
          options.resources."volumeSnapshots";
      "snapshot.storage.k8s.io"."v1"."VolumeSnapshotClass" =
        mkAliasDefinitions
          options.resources."volumeSnapshotClasses";
      "snapshot.storage.k8s.io"."v1"."VolumeSnapshotContent" =
        mkAliasDefinitions
          options.resources."volumeSnapshotContents";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "groupsnapshot.storage.k8s.io";
        version = "v1";
        kind = "VolumeGroupSnapshot";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "groupsnapshot.storage.k8s.io";
        version = "v1beta2";
        kind = "VolumeGroupSnapshot";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "snapshot.storage.k8s.io";
        version = "v1";
        kind = "VolumeSnapshot";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
