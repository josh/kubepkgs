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
    "jetstream.nats.io.v1beta1.Consumer" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta1.ConsumerSpec"));
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta1.ConsumerStatus"));
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
    "jetstream.nats.io.v1beta1.ConsumerSpec" = {

      options = {
        "ackPolicy" = mkOption {
          description = "How messages should be acknowledged.";
          type = (
            types.nullOr (
              types.enum [
                "none"
                "all"
                "explicit"
                "flow_control"
              ]
            )
          );
        };
        "ackWait" = mkOption {
          description = "How long to allow messages to remain un-acknowledged before attempting redelivery.";
          type = (types.nullOr types.str);
        };
        "deliverGroup" = mkOption {
          description = "The name of a queue group.";
          type = (types.nullOr types.str);
        };
        "deliverPolicy" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.enum [
                "all"
                "last"
                "new"
                "byStartSequence"
                "byStartTime"
              ]
            )
          );
        };
        "deliverSubject" = mkOption {
          description = "The subject to deliver observed messages, when not set, a pull-based Consumer is created.";
          type = (types.nullOr types.str);
        };
        "description" = mkOption {
          description = "The description of the consumer.";
          type = (types.nullOr types.str);
        };
        "durableName" = mkOption {
          description = "The name of the Consumer.";
          type = (types.nullOr (types.withMinLength 1 types.str));
        };
        "filterSubject" = mkOption {
          description = "Select only a specific incoming subjects, supports wildcards.";
          type = (types.nullOr types.str);
        };
        "flowControl" = mkOption {
          description = "Enables flow control.";
          type = (types.nullOr types.bool);
        };
        "heartbeatInterval" = mkOption {
          description = "The interval used to deliver idle heartbeats for push-based consumers, in Go's time.Duration format.";
          type = (types.nullOr types.str);
        };
        "maxAckPending" = mkOption {
          description = "Maximum pending Acks before consumers are paused.";
          type = (types.nullOr types.int);
        };
        "maxDeliver" = mkOption {
          description = "";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "optStartSeq" = mkOption {
          description = "";
          type = (types.nullOr (types.withMinimum 0 types.int));
        };
        "optStartTime" = mkOption {
          description = "Time format must be RFC3339.";
          type = (types.nullOr types.str);
        };
        "rateLimitBps" = mkOption {
          description = "Rate at which messages will be delivered to clients, expressed in bit per second.";
          type = (types.nullOr types.int);
        };
        "replayPolicy" = mkOption {
          description = "How messages are sent.";
          type = (
            types.nullOr (
              types.enum [
                "instant"
                "original"
              ]
            )
          );
        };
        "sampleFreq" = mkOption {
          description = "What percentage of acknowledgements should be samples for observability.";
          type = (types.nullOr types.str);
        };
        "streamName" = mkOption {
          description = "The name of the Stream to create the Consumer in.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "ackPolicy" = mkOverride 1002 null;
        "ackWait" = mkOverride 1002 null;
        "deliverGroup" = mkOverride 1002 null;
        "deliverPolicy" = mkOverride 1002 null;
        "deliverSubject" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "durableName" = mkOverride 1002 null;
        "filterSubject" = mkOverride 1002 null;
        "flowControl" = mkOverride 1002 null;
        "heartbeatInterval" = mkOverride 1002 null;
        "maxAckPending" = mkOverride 1002 null;
        "maxDeliver" = mkOverride 1002 null;
        "optStartSeq" = mkOverride 1002 null;
        "optStartTime" = mkOverride 1002 null;
        "rateLimitBps" = mkOverride 1002 null;
        "replayPolicy" = mkOverride 1002 null;
        "sampleFreq" = mkOverride 1002 null;
        "streamName" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.ConsumerStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "jetstream.nats.io.v1beta1.ConsumerStatusConditions"))
          );
        };
        "observedGeneration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.ConsumerStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.Stream" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta1.StreamSpec"));
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta1.StreamStatus"));
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
    "jetstream.nats.io.v1beta1.StreamSpec" = {

      options = {
        "description" = mkOption {
          description = "The description of the stream.";
          type = (types.nullOr types.str);
        };
        "discard" = mkOption {
          description = "When a Stream reach it's limits either old messages are deleted or new ones are denied.";
          type = (
            types.nullOr (
              types.enum [
                "old"
                "new"
              ]
            )
          );
        };
        "duplicateWindow" = mkOption {
          description = "The duration window to track duplicate messages for.";
          type = (types.nullOr types.str);
        };
        "maxAge" = mkOption {
          description = "Maximum age of any message in the stream, expressed in Go's time.Duration format. Empty for unlimited.";
          type = (types.nullOr types.str);
        };
        "maxBytes" = mkOption {
          description = "How big the Stream may be, when the combined stream size exceeds this old messages are removed. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxConsumers" = mkOption {
          description = "How many Consumers can be defined for a given Stream. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxMsgSize" = mkOption {
          description = "The largest message that will be accepted by the Stream. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxMsgs" = mkOption {
          description = "How many messages may be in a Stream, oldest messages will be removed if the Stream exceeds this size. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxMsgsPerSubject" = mkOption {
          description = "The maximum number of messages per subject.";
          type = (types.nullOr types.int);
        };
        "mirror" = mkOption {
          description = "A stream mirror.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta1.StreamSpecMirror"));
        };
        "name" = mkOption {
          description = "A unique name for the Stream.";
          type = (types.nullOr (types.withMinLength 1 types.str));
        };
        "noAck" = mkOption {
          description = "Disables acknowledging messages that are received by the Stream.";
          type = (types.nullOr types.bool);
        };
        "placement" = mkOption {
          description = "A stream's placement.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta1.StreamSpecPlacement"));
        };
        "replicas" = mkOption {
          description = "How many replicas to keep for each message.";
          type = (types.nullOr (types.withMinimum 1 types.int));
        };
        "retention" = mkOption {
          description = "How messages are retained in the Stream, once this is exceeded old messages are removed.";
          type = (
            types.nullOr (
              types.enum [
                "limits"
                "interest"
                "workqueue"
              ]
            )
          );
        };
        "sources" = mkOption {
          description = "A stream's sources.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "jetstream.nats.io.v1beta1.StreamSpecSources" "name" [ ]
            )
          );
          apply = attrsToList;
        };
        "storage" = mkOption {
          description = "The storage backend to use for the Stream.";
          type = (
            types.nullOr (
              types.enum [
                "file"
                "memory"
              ]
            )
          );
        };
        "subjects" = mkOption {
          description = "A list of subjects to consume, supports wildcards.";
          type = (types.nullOr (types.listOf (types.withMinLength 1 types.str)));
        };
      };

      config = {
        "description" = mkOverride 1002 null;
        "discard" = mkOverride 1002 null;
        "duplicateWindow" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
        "maxBytes" = mkOverride 1002 null;
        "maxConsumers" = mkOverride 1002 null;
        "maxMsgSize" = mkOverride 1002 null;
        "maxMsgs" = mkOverride 1002 null;
        "maxMsgsPerSubject" = mkOverride 1002 null;
        "mirror" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "noAck" = mkOverride 1002 null;
        "placement" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "retention" = mkOverride 1002 null;
        "sources" = mkOverride 1002 null;
        "storage" = mkOverride 1002 null;
        "subjects" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.StreamSpecMirror" = {

      options = {
        "externalApiPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "externalDeliverPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "filterSubject" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "optStartSeq" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "optStartTime" = mkOption {
          description = "Time format must be RFC3339.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "externalApiPrefix" = mkOverride 1002 null;
        "externalDeliverPrefix" = mkOverride 1002 null;
        "filterSubject" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optStartSeq" = mkOverride 1002 null;
        "optStartTime" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.StreamSpecPlacement" = {

      options = {
        "cluster" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "tags" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "cluster" = mkOverride 1002 null;
        "tags" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.StreamSpecSources" = {

      options = {
        "externalApiPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "externalDeliverPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "filterSubject" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "optStartSeq" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "optStartTime" = mkOption {
          description = "Time format must be RFC3339.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "externalApiPrefix" = mkOverride 1002 null;
        "externalDeliverPrefix" = mkOverride 1002 null;
        "filterSubject" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optStartSeq" = mkOverride 1002 null;
        "optStartTime" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.StreamStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "jetstream.nats.io.v1beta1.StreamStatusConditions"))
          );
        };
        "observedGeneration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.StreamStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.StreamTemplate" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta1.StreamTemplateSpec"));
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta1.StreamTemplateStatus"));
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
    "jetstream.nats.io.v1beta1.StreamTemplateSpec" = {

      options = {
        "discard" = mkOption {
          description = "When a Stream reach it's limits either old messages are deleted or new ones are denied.";
          type = (
            types.nullOr (
              types.enum [
                "old"
                "new"
              ]
            )
          );
        };
        "duplicateWindow" = mkOption {
          description = "The duration window to track duplicate messages for.";
          type = (types.nullOr types.str);
        };
        "maxAge" = mkOption {
          description = "Maximum age of any message in the stream, expressed in Go's time.Duration format. Empty for unlimited.";
          type = (types.nullOr types.str);
        };
        "maxBytes" = mkOption {
          description = "How big the Stream may be, when the combined stream size exceeds this old messages are removed. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxConsumers" = mkOption {
          description = "How many Consumers can be defined for a given Stream. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxMsgSize" = mkOption {
          description = "The largest message that will be accepted by the Stream. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxMsgs" = mkOption {
          description = "How many messages may be in a Stream, oldest messages will be removed if the Stream exceeds this size. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxStreams" = mkOption {
          description = "The maximum number of Streams this Template can create, -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "name" = mkOption {
          description = "A unique name for the Stream Template.";
          type = (types.nullOr (types.withMinLength 1 types.str));
        };
        "noAck" = mkOption {
          description = "Disables acknowledging messages that are received by the Stream.";
          type = (types.nullOr types.bool);
        };
        "replicas" = mkOption {
          description = "How many replicas to keep for each message.";
          type = (types.nullOr (types.withMinimum 1 types.int));
        };
        "retention" = mkOption {
          description = "How messages are retained in the Stream, once this is exceeded old messages are removed.";
          type = (
            types.nullOr (
              types.enum [
                "limits"
                "interest"
                "workqueue"
              ]
            )
          );
        };
        "storage" = mkOption {
          description = "The storage backend to use for the Stream.";
          type = (
            types.nullOr (
              types.enum [
                "file"
                "memory"
              ]
            )
          );
        };
        "subjects" = mkOption {
          description = "A list of subjects to consume, supports wildcards.";
          type = (types.nullOr (types.listOf (types.withMinLength 1 types.str)));
        };
      };

      config = {
        "discard" = mkOverride 1002 null;
        "duplicateWindow" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
        "maxBytes" = mkOverride 1002 null;
        "maxConsumers" = mkOverride 1002 null;
        "maxMsgSize" = mkOverride 1002 null;
        "maxMsgs" = mkOverride 1002 null;
        "maxStreams" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "noAck" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "retention" = mkOverride 1002 null;
        "storage" = mkOverride 1002 null;
        "subjects" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.StreamTemplateStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "jetstream.nats.io.v1beta1.StreamTemplateStatusConditions"))
          );
        };
        "observedGeneration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta1.StreamTemplateStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.Account" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpec"));
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountStatus"));
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
    "jetstream.nats.io.v1beta2.AccountSpec" = {

      options = {
        "creds" = mkOption {
          description = "The creds to be used to connect to the NATS Service.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpecCreds"));
        };
        "name" = mkOption {
          description = "A unique name for the Account.";
          type = (types.nullOr (types.withMinLength 1 types.str));
        };
        "nkey" = mkOption {
          description = "The NKey seed to be used to connect to the NATS Service.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpecNkey"));
        };
        "servers" = mkOption {
          description = "A list of servers to connect.";
          type = (types.nullOr (types.listOf (types.withMinLength 1 types.str)));
        };
        "tls" = mkOption {
          description = "The TLS certs to be used to connect to the NATS Service.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpecTls"));
        };
        "tlsFirst" = mkOption {
          description = "When true, the KV Store will initiate TLS before server INFO.";
          type = (types.nullOr types.bool);
        };
        "token" = mkOption {
          description = "The token to be used to connect to the NATS Service.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpecToken"));
        };
        "user" = mkOption {
          description = "The user and password to be used to connect to the NATS Service.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpecUser"));
        };
      };

      config = {
        "creds" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "nkey" = mkOverride 1002 null;
        "servers" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "tlsFirst" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountSpecCreds" = {

      options = {
        "file" = mkOption {
          description = "Credentials file, generated with github.com/nats-io/nsc tool.";
          type = (types.nullOr types.str);
        };
        "secret" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpecCredsSecret"));
        };
      };

      config = {
        "file" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountSpecCredsSecret" = {

      options = {
        "name" = mkOption {
          description = "Name of the secret with the creds.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountSpecNkey" = {

      options = {
        "secret" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpecNkeySecret"));
        };
        "seed" = mkOption {
          description = "Key in the secret that contains the NKey seed.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secret" = mkOverride 1002 null;
        "seed" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountSpecNkeySecret" = {

      options = {
        "name" = mkOption {
          description = "Name of the secret containing the NKey seed.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountSpecTls" = {

      options = {
        "ca" = mkOption {
          description = "Filename of the Root CA of the TLS cert.";
          type = (types.nullOr types.str);
        };
        "cert" = mkOption {
          description = "Filename of the TLS cert.";
          type = (types.nullOr types.str);
        };
        "key" = mkOption {
          description = "Filename of the TLS cert key.";
          type = (types.nullOr types.str);
        };
        "secret" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpecTlsSecret"));
        };
      };

      config = {
        "ca" = mkOverride 1002 null;
        "cert" = mkOverride 1002 null;
        "key" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountSpecTlsSecret" = {

      options = {
        "name" = mkOption {
          description = "Name of the TLS secret with the certs.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountSpecToken" = {

      options = {
        "secret" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpecTokenSecret"));
        };
        "token" = mkOption {
          description = "Key in the secret that contains the token.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "secret" = mkOverride 1002 null;
        "token" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountSpecTokenSecret" = {

      options = {
        "name" = mkOption {
          description = "Name of the secret with the token.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountSpecUser" = {

      options = {
        "password" = mkOption {
          description = "Key in the secret that contains the password.";
          type = (types.nullOr types.str);
        };
        "secret" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.AccountSpecUserSecret"));
        };
        "user" = mkOption {
          description = "Key in the secret that contains the user.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "password" = mkOverride 1002 null;
        "secret" = mkOverride 1002 null;
        "user" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountSpecUserSecret" = {

      options = {
        "name" = mkOption {
          description = "Name of the secret with the user and password.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "name" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "jetstream.nats.io.v1beta2.AccountStatusConditions"))
          );
        };
        "observedGeneration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.AccountStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.Consumer" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.ConsumerSpec"));
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.ConsumerStatus"));
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
    "jetstream.nats.io.v1beta2.ConsumerSpec" = {

      options = {
        "account" = mkOption {
          description = "Name of the account to which the Consumer belongs.";
          type = (types.nullOr types.str);
        };
        "ackPolicy" = mkOption {
          description = "How messages should be acknowledged.";
          type = (
            types.nullOr (
              types.enum [
                "none"
                "all"
                "explicit"
                "flow_control"
              ]
            )
          );
        };
        "ackWait" = mkOption {
          description = "How long to allow messages to remain un-acknowledged before attempting redelivery.";
          type = (types.nullOr types.str);
        };
        "backoff" = mkOption {
          description = "List of durations representing a retry time scale for NaK'd or retried messages.";
          type = (types.nullOr (types.listOf types.str));
        };
        "creds" = mkOption {
          description = "NATS user credentials for connecting to servers. Please make sure your controller has mounted the creds on its path.";
          type = (types.nullOr types.str);
        };
        "deliverGroup" = mkOption {
          description = "The name of a queue group.";
          type = (types.nullOr types.str);
        };
        "deliverPolicy" = mkOption {
          description = "";
          type = (
            types.nullOr (
              types.enum [
                "all"
                "last"
                "new"
                "byStartSequence"
                "byStartTime"
                "lastPerSubject"
              ]
            )
          );
        };
        "deliverSubject" = mkOption {
          description = "The subject to deliver observed messages, when not set, a pull-based Consumer is created.";
          type = (types.nullOr types.str);
        };
        "description" = mkOption {
          description = "The description of the consumer.";
          type = (types.nullOr types.str);
        };
        "durableName" = mkOption {
          description = "The name of the Consumer.";
          type = (types.nullOr (types.withMinLength 1 types.str));
        };
        "filterSubject" = mkOption {
          description = "Select only a specific incoming subjects, supports wildcards.";
          type = (types.nullOr types.str);
        };
        "filterSubjects" = mkOption {
          description = "List of incoming subjects, supports wildcards. Available since 2.10.";
          type = (types.nullOr (types.listOf types.str));
        };
        "flowControl" = mkOption {
          description = "Enables flow control.";
          type = (types.nullOr types.bool);
        };
        "headersOnly" = mkOption {
          description = "When set, only the headers of messages in the stream are delivered, and not the bodies. Additionally, Nats-Msg-Size header is added to indicate the size of the removed payload.";
          type = (types.nullOr types.bool);
        };
        "heartbeatInterval" = mkOption {
          description = "The interval used to deliver idle heartbeats for push-based consumers, in Go's time.Duration format.";
          type = (types.nullOr types.str);
        };
        "inactiveThreshold" = mkOption {
          description = "The idle time an Ephemeral Consumer allows before it is removed.";
          type = (types.nullOr types.str);
        };
        "jsDomain" = mkOption {
          description = "The JetStream domain to use for the consumer.";
          type = (types.nullOr types.str);
        };
        "maxAckPending" = mkOption {
          description = "Maximum pending Acks before consumers are paused.";
          type = (types.nullOr types.int);
        };
        "maxDeliver" = mkOption {
          description = "";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxRequestBatch" = mkOption {
          description = "The largest batch property that may be specified when doing a pull on a Pull Consumer.";
          type = (types.nullOr types.int);
        };
        "maxRequestExpires" = mkOption {
          description = "The maximum expires duration that may be set when doing a pull on a Pull Consumer.";
          type = (types.nullOr types.str);
        };
        "maxRequestMaxBytes" = mkOption {
          description = "The maximum max_bytes value that maybe set when dong a pull on a Pull Consumer.";
          type = (types.nullOr types.int);
        };
        "maxWaiting" = mkOption {
          description = "The number of pulls that can be outstanding on a pull consumer, pulls received after this is reached are ignored.";
          type = (types.nullOr types.int);
        };
        "memStorage" = mkOption {
          description = "Force the consumer state to be kept in memory rather than inherit the setting from the stream.";
          type = (types.nullOr types.bool);
        };
        "metadata" = mkOption {
          description = "Additional Consumer metadata.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "nkey" = mkOption {
          description = "NATS user NKey for connecting to servers.";
          type = (types.nullOr types.str);
        };
        "optStartSeq" = mkOption {
          description = "";
          type = (types.nullOr (types.withMinimum 0 types.int));
        };
        "optStartTime" = mkOption {
          description = "Time format must be RFC3339.";
          type = (types.nullOr types.str);
        };
        "pauseUntil" = mkOption {
          description = "RFC3339 timestamp until which the consumer should be paused.";
          type = (types.nullOr types.str);
        };
        "pinnedTtl" = mkOption {
          description = "TTL for pinned client when using pinned_client priority policy.";
          type = (types.nullOr types.str);
        };
        "preventDelete" = mkOption {
          description = "When true, the managed Consumer will not be deleted when the resource is deleted.";
          type = (types.nullOr types.bool);
        };
        "preventUpdate" = mkOption {
          description = "When true, the managed Consumer will not be updated when the resource is updated.";
          type = (types.nullOr types.bool);
        };
        "priorityGroups" = mkOption {
          description = "List of priority groups for the consumer. For now, only one group is supported.";
          type = (types.nullOr (types.listOf types.str));
        };
        "priorityPolicy" = mkOption {
          description = "Priority policy for consumer (pinned_client, overflow, prioritized, or none).";
          type = (types.nullOr types.str);
        };
        "rateLimitBps" = mkOption {
          description = "Rate at which messages will be delivered to clients, expressed in bit per second.";
          type = (types.nullOr types.int);
        };
        "replayPolicy" = mkOption {
          description = "How messages are sent.";
          type = (
            types.nullOr (
              types.enum [
                "instant"
                "original"
              ]
            )
          );
        };
        "replicas" = mkOption {
          description = "When set do not inherit the replica count from the stream but specifically set it to this amount.";
          type = (types.nullOr types.int);
        };
        "sampleFreq" = mkOption {
          description = "What percentage of acknowledgements should be samples for observability.";
          type = (types.nullOr types.str);
        };
        "servers" = mkOption {
          description = "A list of servers for creating consumer.";
          type = (types.nullOr (types.listOf types.str));
        };
        "streamName" = mkOption {
          description = "The name of the Stream to create the Consumer in.";
          type = (types.nullOr types.str);
        };
        "tls" = mkOption {
          description = "A client's TLS certs and keys.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.ConsumerSpecTls"));
        };
        "tlsFirst" = mkOption {
          description = "When true, the KV Store will initiate TLS before server INFO.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "account" = mkOverride 1002 null;
        "ackPolicy" = mkOverride 1002 null;
        "ackWait" = mkOverride 1002 null;
        "backoff" = mkOverride 1002 null;
        "creds" = mkOverride 1002 null;
        "deliverGroup" = mkOverride 1002 null;
        "deliverPolicy" = mkOverride 1002 null;
        "deliverSubject" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "durableName" = mkOverride 1002 null;
        "filterSubject" = mkOverride 1002 null;
        "filterSubjects" = mkOverride 1002 null;
        "flowControl" = mkOverride 1002 null;
        "headersOnly" = mkOverride 1002 null;
        "heartbeatInterval" = mkOverride 1002 null;
        "inactiveThreshold" = mkOverride 1002 null;
        "jsDomain" = mkOverride 1002 null;
        "maxAckPending" = mkOverride 1002 null;
        "maxDeliver" = mkOverride 1002 null;
        "maxRequestBatch" = mkOverride 1002 null;
        "maxRequestExpires" = mkOverride 1002 null;
        "maxRequestMaxBytes" = mkOverride 1002 null;
        "maxWaiting" = mkOverride 1002 null;
        "memStorage" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "nkey" = mkOverride 1002 null;
        "optStartSeq" = mkOverride 1002 null;
        "optStartTime" = mkOverride 1002 null;
        "pauseUntil" = mkOverride 1002 null;
        "pinnedTtl" = mkOverride 1002 null;
        "preventDelete" = mkOverride 1002 null;
        "preventUpdate" = mkOverride 1002 null;
        "priorityGroups" = mkOverride 1002 null;
        "priorityPolicy" = mkOverride 1002 null;
        "rateLimitBps" = mkOverride 1002 null;
        "replayPolicy" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "sampleFreq" = mkOverride 1002 null;
        "servers" = mkOverride 1002 null;
        "streamName" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "tlsFirst" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.ConsumerSpecTls" = {

      options = {
        "clientCert" = mkOption {
          description = "A client's cert filepath. Should be mounted.";
          type = (types.nullOr types.str);
        };
        "clientKey" = mkOption {
          description = "A client's key filepath. Should be mounted.";
          type = (types.nullOr types.str);
        };
        "rootCas" = mkOption {
          description = "A list of filepaths to CAs. Should be mounted.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "clientCert" = mkOverride 1002 null;
        "clientKey" = mkOverride 1002 null;
        "rootCas" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.ConsumerStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "jetstream.nats.io.v1beta2.ConsumerStatusConditions"))
          );
        };
        "observedGeneration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.ConsumerStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.KeyValue" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.KeyValueSpec"));
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.KeyValueStatus"));
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
    "jetstream.nats.io.v1beta2.KeyValueSpec" = {

      options = {
        "account" = mkOption {
          description = "Name of the account to which the Stream belongs.";
          type = (types.nullOr types.str);
        };
        "bucket" = mkOption {
          description = "A unique name for the KV Store.";
          type = (types.nullOr types.str);
        };
        "compression" = mkOption {
          description = "KV Store compression.";
          type = (types.nullOr types.bool);
        };
        "creds" = mkOption {
          description = "NATS user credentials for connecting to servers. Please make sure your controller has mounted the creds on its path.";
          type = (types.nullOr types.str);
        };
        "description" = mkOption {
          description = "The description of the KV Store.";
          type = (types.nullOr types.str);
        };
        "history" = mkOption {
          description = "The number of historical values to keep per key.";
          type = (types.nullOr types.int);
        };
        "jsDomain" = mkOption {
          description = "The JetStream domain to use for the KV store.";
          type = (types.nullOr types.str);
        };
        "limitMarkerTtl" = mkOption {
          description = "LimitMarkerTTL is how long the bucket keeps markers when keys are removed by the TTL setting, 0 meaning markers are not supported";
          type = (types.nullOr types.int);
        };
        "maxBytes" = mkOption {
          description = "The maximum size of the KV Store in bytes.";
          type = (types.nullOr types.int);
        };
        "maxValueSize" = mkOption {
          description = "The maximum size of a value in bytes.";
          type = (types.nullOr types.int);
        };
        "mirror" = mkOption {
          description = "A KV Store mirror.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.KeyValueSpecMirror"));
        };
        "nkey" = mkOption {
          description = "NATS user NKey for connecting to servers.";
          type = (types.nullOr types.str);
        };
        "placement" = mkOption {
          description = "The KV Store placement via tags or cluster name.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.KeyValueSpecPlacement"));
        };
        "preventDelete" = mkOption {
          description = "When true, the managed KV Store will not be deleted when the resource is deleted.";
          type = (types.nullOr types.bool);
        };
        "preventUpdate" = mkOption {
          description = "When true, the managed KV Store will not be updated when the resource is updated.";
          type = (types.nullOr types.bool);
        };
        "replicas" = mkOption {
          description = "The number of replicas to keep for the KV Store in clustered JetStream.";
          type = (types.nullOr (types.withMaximum 5 (types.withMinimum 1 types.int)));
        };
        "republish" = mkOption {
          description = "Republish configuration for the KV Store.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.KeyValueSpecRepublish"));
        };
        "servers" = mkOption {
          description = "A list of servers for creating the KV Store.";
          type = (types.nullOr (types.listOf types.str));
        };
        "sources" = mkOption {
          description = "A KV Store's sources.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "jetstream.nats.io.v1beta2.KeyValueSpecSources" "name" [ ]
            )
          );
          apply = attrsToList;
        };
        "storage" = mkOption {
          description = "The storage backend to use for the KV Store.";
          type = (
            types.nullOr (
              types.enum [
                "file"
                "memory"
              ]
            )
          );
        };
        "tls" = mkOption {
          description = "A client's TLS certs and keys.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.KeyValueSpecTls"));
        };
        "tlsFirst" = mkOption {
          description = "When true, the KV Store will initiate TLS before server INFO.";
          type = (types.nullOr types.bool);
        };
        "ttl" = mkOption {
          description = "The time expiry for keys.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "account" = mkOverride 1002 null;
        "bucket" = mkOverride 1002 null;
        "compression" = mkOverride 1002 null;
        "creds" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "history" = mkOverride 1002 null;
        "jsDomain" = mkOverride 1002 null;
        "limitMarkerTtl" = mkOverride 1002 null;
        "maxBytes" = mkOverride 1002 null;
        "maxValueSize" = mkOverride 1002 null;
        "mirror" = mkOverride 1002 null;
        "nkey" = mkOverride 1002 null;
        "placement" = mkOverride 1002 null;
        "preventDelete" = mkOverride 1002 null;
        "preventUpdate" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "republish" = mkOverride 1002 null;
        "servers" = mkOverride 1002 null;
        "sources" = mkOverride 1002 null;
        "storage" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "tlsFirst" = mkOverride 1002 null;
        "ttl" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.KeyValueSpecMirror" = {

      options = {
        "externalApiPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "externalDeliverPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "filterSubject" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "optStartSeq" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "optStartTime" = mkOption {
          description = "Time format must be RFC3339.";
          type = (types.nullOr types.str);
        };
        "subjectTransforms" = mkOption {
          description = "List of subject transforms for this mirror.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "jetstream.nats.io.v1beta2.KeyValueSpecMirrorSubjectTransforms")
            )
          );
        };
      };

      config = {
        "externalApiPrefix" = mkOverride 1002 null;
        "externalDeliverPrefix" = mkOverride 1002 null;
        "filterSubject" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optStartSeq" = mkOverride 1002 null;
        "optStartTime" = mkOverride 1002 null;
        "subjectTransforms" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.KeyValueSpecMirrorSubjectTransforms" = {

      options = {
        "dest" = mkOption {
          description = "Destination subject.";
          type = (types.nullOr types.str);
        };
        "source" = mkOption {
          description = "Source subject.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "dest" = mkOverride 1002 null;
        "source" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.KeyValueSpecPlacement" = {

      options = {
        "cluster" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "tags" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "cluster" = mkOverride 1002 null;
        "tags" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.KeyValueSpecRepublish" = {

      options = {
        "destination" = mkOption {
          description = "Messages will be additionally published to this subject after Bucket.";
          type = (types.nullOr types.str);
        };
        "source" = mkOption {
          description = "Messages will be published from this subject to the destination subject.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "destination" = mkOverride 1002 null;
        "source" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.KeyValueSpecSources" = {

      options = {
        "externalApiPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "externalDeliverPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "filterSubject" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "optStartSeq" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "optStartTime" = mkOption {
          description = "Time format must be RFC3339.";
          type = (types.nullOr types.str);
        };
        "subjectTransforms" = mkOption {
          description = "List of subject transforms for this mirror.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "jetstream.nats.io.v1beta2.KeyValueSpecSourcesSubjectTransforms")
            )
          );
        };
      };

      config = {
        "externalApiPrefix" = mkOverride 1002 null;
        "externalDeliverPrefix" = mkOverride 1002 null;
        "filterSubject" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optStartSeq" = mkOverride 1002 null;
        "optStartTime" = mkOverride 1002 null;
        "subjectTransforms" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.KeyValueSpecSourcesSubjectTransforms" = {

      options = {
        "dest" = mkOption {
          description = "Destination subject.";
          type = (types.nullOr types.str);
        };
        "source" = mkOption {
          description = "Source subject.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "dest" = mkOverride 1002 null;
        "source" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.KeyValueSpecTls" = {

      options = {
        "clientCert" = mkOption {
          description = "A client's cert filepath. Should be mounted.";
          type = (types.nullOr types.str);
        };
        "clientKey" = mkOption {
          description = "A client's key filepath. Should be mounted.";
          type = (types.nullOr types.str);
        };
        "rootCas" = mkOption {
          description = "A list of filepaths to CAs. Should be mounted.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "clientCert" = mkOverride 1002 null;
        "clientKey" = mkOverride 1002 null;
        "rootCas" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.KeyValueStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "jetstream.nats.io.v1beta2.KeyValueStatusConditions"))
          );
        };
        "observedGeneration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.KeyValueStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.ObjectStore" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.ObjectStoreSpec"));
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.ObjectStoreStatus"));
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
    "jetstream.nats.io.v1beta2.ObjectStoreSpec" = {

      options = {
        "account" = mkOption {
          description = "Name of the account to which the Object Store belongs.";
          type = (types.nullOr types.str);
        };
        "bucket" = mkOption {
          description = "A unique name for the Object Store.";
          type = (types.nullOr types.str);
        };
        "compression" = mkOption {
          description = "Object Store compression.";
          type = (types.nullOr types.bool);
        };
        "creds" = mkOption {
          description = "NATS user credentials for connecting to servers. Please make sure your controller has mounted the creds on its path.";
          type = (types.nullOr types.str);
        };
        "description" = mkOption {
          description = "The description of the Object Store.";
          type = (types.nullOr types.str);
        };
        "jsDomain" = mkOption {
          description = "The JetStream domain to use for the Object Store.";
          type = (types.nullOr types.str);
        };
        "maxBytes" = mkOption {
          description = "The maximum size of the Store in bytes.";
          type = (types.nullOr types.int);
        };
        "metadata" = mkOption {
          description = "Additional Object Store metadata.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "nkey" = mkOption {
          description = "NATS user NKey for connecting to servers.";
          type = (types.nullOr types.str);
        };
        "placement" = mkOption {
          description = "The Object Store placement via tags or cluster name.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.ObjectStoreSpecPlacement"));
        };
        "preventDelete" = mkOption {
          description = "When true, the managed Object Store will not be deleted when the resource is deleted.";
          type = (types.nullOr types.bool);
        };
        "preventUpdate" = mkOption {
          description = "When true, the managed Object Store will not be updated when the resource is updated.";
          type = (types.nullOr types.bool);
        };
        "replicas" = mkOption {
          description = "The number of replicas to keep for the Object Store in clustered JetStream.";
          type = (types.nullOr (types.withMaximum 5 (types.withMinimum 1 types.int)));
        };
        "servers" = mkOption {
          description = "A list of servers for creating the Object Store.";
          type = (types.nullOr (types.listOf types.str));
        };
        "storage" = mkOption {
          description = "The storage backend to use for the Object Store.";
          type = (
            types.nullOr (
              types.enum [
                "file"
                "memory"
              ]
            )
          );
        };
        "tls" = mkOption {
          description = "A client's TLS certs and keys.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.ObjectStoreSpecTls"));
        };
        "tlsFirst" = mkOption {
          description = "When true, the Object Store will initiate TLS before server INFO.";
          type = (types.nullOr types.bool);
        };
        "ttl" = mkOption {
          description = "The time expiry for keys.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "account" = mkOverride 1002 null;
        "bucket" = mkOverride 1002 null;
        "compression" = mkOverride 1002 null;
        "creds" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "jsDomain" = mkOverride 1002 null;
        "maxBytes" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "nkey" = mkOverride 1002 null;
        "placement" = mkOverride 1002 null;
        "preventDelete" = mkOverride 1002 null;
        "preventUpdate" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "servers" = mkOverride 1002 null;
        "storage" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "tlsFirst" = mkOverride 1002 null;
        "ttl" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.ObjectStoreSpecPlacement" = {

      options = {
        "cluster" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "tags" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "cluster" = mkOverride 1002 null;
        "tags" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.ObjectStoreSpecTls" = {

      options = {
        "clientCert" = mkOption {
          description = "A client's cert filepath. Should be mounted.";
          type = (types.nullOr types.str);
        };
        "clientKey" = mkOption {
          description = "A client's key filepath. Should be mounted.";
          type = (types.nullOr types.str);
        };
        "rootCas" = mkOption {
          description = "A list of filepaths to CAs. Should be mounted.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "clientCert" = mkOverride 1002 null;
        "clientKey" = mkOverride 1002 null;
        "rootCas" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.ObjectStoreStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "jetstream.nats.io.v1beta2.ObjectStoreStatusConditions"))
          );
        };
        "observedGeneration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.ObjectStoreStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.Stream" = {

      options = {
        "apiVersion" = mkOption {
          description = "\nAPIVersion defines the versioned schema of this representation of an object.\nServers should convert recognized schemas to the latest internal value, and\nmay reject unrecognized values.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources\n";
          type = (types.nullOr types.str);
        };
        "kind" = mkOption {
          description = "\nKind is a string value representing the REST resource this object represents.\nServers may infer this from the endpoint the client submits requests to.\nCannot be updated.\nIn CamelCase.\nMore info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds\n";
          type = (types.nullOr types.str);
        };
        "metadata" = mkOption {
          description = "Standard object's metadata. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#metadata";
          type = (types.nullOr (globalSubmoduleOf "io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta"));
        };
        "spec" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.StreamSpec"));
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.StreamStatus"));
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
    "jetstream.nats.io.v1beta2.StreamSpec" = {

      options = {
        "account" = mkOption {
          description = "Name of the account to which the Stream belongs.";
          type = (types.nullOr types.str);
        };
        "allowAtomicPublish" = mkOption {
          description = "When true, enables atomic batch publishing.";
          type = (types.nullOr types.bool);
        };
        "allowBatched" = mkOption {
          description = "When true, enables fast-ingest batch publishing (nats-server 2.14+).";
          type = (types.nullOr types.bool);
        };
        "allowDirect" = mkOption {
          description = "When true, allow higher performance, direct access to get individual messages.";
          type = (types.nullOr types.bool);
        };
        "allowMsgCounter" = mkOption {
          description = "When true, enables message counters for the stream.";
          type = (types.nullOr types.bool);
        };
        "allowMsgSchedules" = mkOption {
          description = "When true, enables message scheduling.";
          type = (types.nullOr types.bool);
        };
        "allowMsgTtl" = mkOption {
          description = "When true, allows header initiated per-message TTLs. If disabled, then the `NATS-TTL` header will be ignored.";
          type = (types.nullOr types.bool);
        };
        "allowRollup" = mkOption {
          description = "When true, allows the use of the Nats-Rollup header to replace all contents of a stream, or subject in a stream, with a single new message.";
          type = (types.nullOr types.bool);
        };
        "compression" = mkOption {
          description = "Stream specific compression.";
          type = (
            types.nullOr (
              types.enum [
                "s2"
                "none"
                ""
              ]
            )
          );
        };
        "consumerLimits" = mkOption {
          description = "";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.StreamSpecConsumerLimits"));
        };
        "creds" = mkOption {
          description = "NATS user credentials for connecting to servers. Please make sure your controller has mounted the creds on this path.";
          type = (types.nullOr types.str);
        };
        "denyDelete" = mkOption {
          description = "When true, restricts the ability to delete messages from a stream via the API. Cannot be changed once set to true.";
          type = (types.nullOr types.bool);
        };
        "denyPurge" = mkOption {
          description = "When true, restricts the ability to purge a stream via the API. Cannot be changed once set to true.";
          type = (types.nullOr types.bool);
        };
        "description" = mkOption {
          description = "The description of the stream.";
          type = (types.nullOr types.str);
        };
        "discard" = mkOption {
          description = "When a Stream reach it's limits either old messages are deleted or new ones are denied.";
          type = (
            types.nullOr (
              types.enum [
                "old"
                "new"
              ]
            )
          );
        };
        "discardPerSubject" = mkOption {
          description = "Applies discard policy on a per-subject basis. Requires discard policy 'new' and 'maxMsgs' to be set.";
          type = (types.nullOr types.bool);
        };
        "duplicateWindow" = mkOption {
          description = "The duration window to track duplicate messages for.";
          type = (types.nullOr types.str);
        };
        "firstSequence" = mkOption {
          description = "Sequence number from which the Stream will start.";
          type = (types.nullOr (types.either types.int types.float));
        };
        "jsDomain" = mkOption {
          description = "The JetStream domain to use for the stream.";
          type = (types.nullOr types.str);
        };
        "maxAge" = mkOption {
          description = "Maximum age of any message in the stream, expressed in Go's time.Duration format. Empty for unlimited.";
          type = (types.nullOr types.str);
        };
        "maxBytes" = mkOption {
          description = "How big the Stream may be, when the combined stream size exceeds this old messages are removed. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxConsumers" = mkOption {
          description = "How many Consumers can be defined for a given Stream. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxMsgSize" = mkOption {
          description = "The largest message that will be accepted by the Stream. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxMsgs" = mkOption {
          description = "How many messages may be in a Stream, oldest messages will be removed if the Stream exceeds this size. -1 for unlimited.";
          type = (types.nullOr (types.withMinimum (-1) types.int));
        };
        "maxMsgsPerSubject" = mkOption {
          description = "The maximum number of messages per subject.";
          type = (types.nullOr types.int);
        };
        "metadata" = mkOption {
          description = "Additional Stream metadata.";
          type = (types.nullOr (types.attrsOf types.str));
        };
        "mirror" = mkOption {
          description = "A stream mirror.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.StreamSpecMirror"));
        };
        "mirrorDirect" = mkOption {
          description = "When true, enables direct access to messages from the origin stream.";
          type = (types.nullOr types.bool);
        };
        "name" = mkOption {
          description = "A unique name for the Stream.";
          type = (types.nullOr (types.withMinLength 1 types.str));
        };
        "nkey" = mkOption {
          description = "NATS user NKey for connecting to servers.";
          type = (types.nullOr types.str);
        };
        "noAck" = mkOption {
          description = "Disables acknowledging messages that are received by the Stream.";
          type = (types.nullOr types.bool);
        };
        "persistMode" = mkOption {
          description = "Configures stream persistence settings (async or default).";
          type = (types.nullOr types.str);
        };
        "placement" = mkOption {
          description = "A stream's placement.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.StreamSpecPlacement"));
        };
        "preventDelete" = mkOption {
          description = "When true, the managed Stream will not be deleted when the resource is deleted.";
          type = (types.nullOr types.bool);
        };
        "preventUpdate" = mkOption {
          description = "When true, the managed Stream will not be updated when the resource is updated.";
          type = (types.nullOr types.bool);
        };
        "replicas" = mkOption {
          description = "How many replicas to keep for each message.";
          type = (types.nullOr (types.withMinimum 1 types.int));
        };
        "republish" = mkOption {
          description = "Republish configuration of the stream.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.StreamSpecRepublish"));
        };
        "retention" = mkOption {
          description = "How messages are retained in the Stream, once this is exceeded old messages are removed.";
          type = (
            types.nullOr (
              types.enum [
                "limits"
                "interest"
                "workqueue"
              ]
            )
          );
        };
        "sealed" = mkOption {
          description = "Seal an existing stream so no new messages may be added.";
          type = (types.nullOr types.bool);
        };
        "servers" = mkOption {
          description = "A list of servers for creating stream.";
          type = (types.nullOr (types.listOf types.str));
        };
        "sources" = mkOption {
          description = "A stream's sources.";
          type = (
            types.nullOr (
              coerceAttrsOfSubmodulesToListByKey "jetstream.nats.io.v1beta2.StreamSpecSources" "name" [ ]
            )
          );
          apply = attrsToList;
        };
        "storage" = mkOption {
          description = "The storage backend to use for the Stream.";
          type = (
            types.nullOr (
              types.enum [
                "file"
                "memory"
              ]
            )
          );
        };
        "subjectDeleteMarkerTtl" = mkOption {
          description = "Enables and sets a duration for adding server markers for delete, purge and max age limits.";
          type = (types.nullOr types.str);
        };
        "subjectTransform" = mkOption {
          description = "SubjectTransform is for applying a subject transform (to matching messages) when a new message is received.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.StreamSpecSubjectTransform"));
        };
        "subjects" = mkOption {
          description = "A list of subjects to consume, supports wildcards.";
          type = (types.nullOr (types.listOf (types.withMinLength 1 types.str)));
        };
        "tls" = mkOption {
          description = "A client's TLS certs and keys.";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.StreamSpecTls"));
        };
        "tlsFirst" = mkOption {
          description = "When true, the KV Store will initiate TLS before server INFO.";
          type = (types.nullOr types.bool);
        };
      };

      config = {
        "account" = mkOverride 1002 null;
        "allowAtomicPublish" = mkOverride 1002 null;
        "allowBatched" = mkOverride 1002 null;
        "allowDirect" = mkOverride 1002 null;
        "allowMsgCounter" = mkOverride 1002 null;
        "allowMsgSchedules" = mkOverride 1002 null;
        "allowMsgTtl" = mkOverride 1002 null;
        "allowRollup" = mkOverride 1002 null;
        "compression" = mkOverride 1002 null;
        "consumerLimits" = mkOverride 1002 null;
        "creds" = mkOverride 1002 null;
        "denyDelete" = mkOverride 1002 null;
        "denyPurge" = mkOverride 1002 null;
        "description" = mkOverride 1002 null;
        "discard" = mkOverride 1002 null;
        "discardPerSubject" = mkOverride 1002 null;
        "duplicateWindow" = mkOverride 1002 null;
        "firstSequence" = mkOverride 1002 null;
        "jsDomain" = mkOverride 1002 null;
        "maxAge" = mkOverride 1002 null;
        "maxBytes" = mkOverride 1002 null;
        "maxConsumers" = mkOverride 1002 null;
        "maxMsgSize" = mkOverride 1002 null;
        "maxMsgs" = mkOverride 1002 null;
        "maxMsgsPerSubject" = mkOverride 1002 null;
        "metadata" = mkOverride 1002 null;
        "mirror" = mkOverride 1002 null;
        "mirrorDirect" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "nkey" = mkOverride 1002 null;
        "noAck" = mkOverride 1002 null;
        "persistMode" = mkOverride 1002 null;
        "placement" = mkOverride 1002 null;
        "preventDelete" = mkOverride 1002 null;
        "preventUpdate" = mkOverride 1002 null;
        "replicas" = mkOverride 1002 null;
        "republish" = mkOverride 1002 null;
        "retention" = mkOverride 1002 null;
        "sealed" = mkOverride 1002 null;
        "servers" = mkOverride 1002 null;
        "sources" = mkOverride 1002 null;
        "storage" = mkOverride 1002 null;
        "subjectDeleteMarkerTtl" = mkOverride 1002 null;
        "subjectTransform" = mkOverride 1002 null;
        "subjects" = mkOverride 1002 null;
        "tls" = mkOverride 1002 null;
        "tlsFirst" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecConsumerLimits" = {

      options = {
        "inactiveThreshold" = mkOption {
          description = "The duration of inactivity after which a consumer is considered inactive.";
          type = (types.nullOr types.str);
        };
        "maxAckPending" = mkOption {
          description = "Maximum number of outstanding unacknowledged messages.";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "inactiveThreshold" = mkOverride 1002 null;
        "maxAckPending" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecMirror" = {

      options = {
        "consumer" = mkOption {
          description = "Reference a durable consumer when sourcing/mirroring (nats-server 2.14+).";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.StreamSpecMirrorConsumer"));
        };
        "externalApiPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "externalDeliverPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "filterSubject" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "optStartSeq" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "optStartTime" = mkOption {
          description = "Time format must be RFC3339.";
          type = (types.nullOr types.str);
        };
        "subjectTransforms" = mkOption {
          description = "List of subject transforms for this mirror.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "jetstream.nats.io.v1beta2.StreamSpecMirrorSubjectTransforms")
            )
          );
        };
      };

      config = {
        "consumer" = mkOverride 1002 null;
        "externalApiPrefix" = mkOverride 1002 null;
        "externalDeliverPrefix" = mkOverride 1002 null;
        "filterSubject" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optStartSeq" = mkOverride 1002 null;
        "optStartTime" = mkOverride 1002 null;
        "subjectTransforms" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecMirrorConsumer" = {

      options = {
        "deliverSubject" = mkOption {
          description = "Deliver subject for the durable push consumer.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Durable consumer name on the source stream.";
          type = types.str;
        };
      };

      config = {
        "deliverSubject" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecMirrorSubjectTransforms" = {

      options = {
        "dest" = mkOption {
          description = "Destination subject.";
          type = (types.nullOr types.str);
        };
        "source" = mkOption {
          description = "Source subject.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "dest" = mkOverride 1002 null;
        "source" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecPlacement" = {

      options = {
        "cluster" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "tags" = mkOption {
          description = "";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "cluster" = mkOverride 1002 null;
        "tags" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecRepublish" = {

      options = {
        "destination" = mkOption {
          description = "Messages will be additionally published to this subject.";
          type = (types.nullOr types.str);
        };
        "source" = mkOption {
          description = "Messages will be published from this subject to the destination subject.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "destination" = mkOverride 1002 null;
        "source" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecSources" = {

      options = {
        "consumer" = mkOption {
          description = "Reference a durable consumer when sourcing/mirroring (nats-server 2.14+).";
          type = (types.nullOr (submoduleOf "jetstream.nats.io.v1beta2.StreamSpecSourcesConsumer"));
        };
        "externalApiPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "externalDeliverPrefix" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "filterSubject" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "optStartSeq" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
        "optStartTime" = mkOption {
          description = "Time format must be RFC3339.";
          type = (types.nullOr types.str);
        };
        "subjectTransforms" = mkOption {
          description = "List of subject transforms for this mirror.";
          type = (
            types.nullOr (
              types.listOf (submoduleOf "jetstream.nats.io.v1beta2.StreamSpecSourcesSubjectTransforms")
            )
          );
        };
      };

      config = {
        "consumer" = mkOverride 1002 null;
        "externalApiPrefix" = mkOverride 1002 null;
        "externalDeliverPrefix" = mkOverride 1002 null;
        "filterSubject" = mkOverride 1002 null;
        "name" = mkOverride 1002 null;
        "optStartSeq" = mkOverride 1002 null;
        "optStartTime" = mkOverride 1002 null;
        "subjectTransforms" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecSourcesConsumer" = {

      options = {
        "deliverSubject" = mkOption {
          description = "Deliver subject for the durable push consumer.";
          type = (types.nullOr types.str);
        };
        "name" = mkOption {
          description = "Durable consumer name on the source stream.";
          type = types.str;
        };
      };

      config = {
        "deliverSubject" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecSourcesSubjectTransforms" = {

      options = {
        "dest" = mkOption {
          description = "Destination subject.";
          type = (types.nullOr types.str);
        };
        "source" = mkOption {
          description = "Source subject.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "dest" = mkOverride 1002 null;
        "source" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecSubjectTransform" = {

      options = {
        "dest" = mkOption {
          description = "Destination subject to transform into.";
          type = (types.nullOr types.str);
        };
        "source" = mkOption {
          description = "Source subject.";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "dest" = mkOverride 1002 null;
        "source" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamSpecTls" = {

      options = {
        "clientCert" = mkOption {
          description = "A client's cert filepath. Should be mounted.";
          type = (types.nullOr types.str);
        };
        "clientKey" = mkOption {
          description = "A client's key filepath. Should be mounted.";
          type = (types.nullOr types.str);
        };
        "rootCas" = mkOption {
          description = "A list of filepaths to CAs. Should be mounted.";
          type = (types.nullOr (types.listOf types.str));
        };
      };

      config = {
        "clientCert" = mkOverride 1002 null;
        "clientKey" = mkOverride 1002 null;
        "rootCas" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamStatus" = {

      options = {
        "conditions" = mkOption {
          description = "";
          type = (
            types.nullOr (types.listOf (submoduleOf "jetstream.nats.io.v1beta2.StreamStatusConditions"))
          );
        };
        "observedGeneration" = mkOption {
          description = "";
          type = (types.nullOr types.int);
        };
      };

      config = {
        "conditions" = mkOverride 1002 null;
        "observedGeneration" = mkOverride 1002 null;
      };

    };
    "jetstream.nats.io.v1beta2.StreamStatusConditions" = {

      options = {
        "lastTransitionTime" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "message" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "reason" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "status" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
        "type" = mkOption {
          description = "";
          type = (types.nullOr types.str);
        };
      };

      config = {
        "lastTransitionTime" = mkOverride 1002 null;
        "message" = mkOverride 1002 null;
        "reason" = mkOverride 1002 null;
        "status" = mkOverride 1002 null;
        "type" = mkOverride 1002 null;
      };

    };

  };
in
{
  # all resource versions
  options = {
    resources = {
      "jetstream.nats.io"."v1beta1"."Consumer" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta1.Consumer" "consumers" "Consumer"
              "jetstream.nats.io"
              "v1beta1"
          )
        );
        default = { };
      };
      "jetstream.nats.io"."v1beta1"."Stream" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta1.Stream" "streams" "Stream" "jetstream.nats.io"
              "v1beta1"
          )
        );
        default = { };
      };
      "jetstream.nats.io"."v1beta1"."StreamTemplate" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta1.StreamTemplate" "streamtemplates" "StreamTemplate"
              "jetstream.nats.io"
              "v1beta1"
          )
        );
        default = { };
      };
      "jetstream.nats.io"."v1beta2"."Account" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta2.Account" "accounts" "Account" "jetstream.nats.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "jetstream.nats.io"."v1beta2"."Consumer" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta2.Consumer" "consumers" "Consumer"
              "jetstream.nats.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "jetstream.nats.io"."v1beta2"."KeyValue" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta2.KeyValue" "keyvalues" "KeyValue"
              "jetstream.nats.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "jetstream.nats.io"."v1beta2"."ObjectStore" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta2.ObjectStore" "objectstores" "ObjectStore"
              "jetstream.nats.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "jetstream.nats.io"."v1beta2"."Stream" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta2.Stream" "streams" "Stream" "jetstream.nats.io"
              "v1beta2"
          )
        );
        default = { };
      };

    }
    // {
      "accounts" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta2.Account" "accounts" "Account" "jetstream.nats.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "consumers" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta2.Consumer" "consumers" "Consumer"
              "jetstream.nats.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "keyValues" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta2.KeyValue" "keyvalues" "KeyValue"
              "jetstream.nats.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "objectStores" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta2.ObjectStore" "objectstores" "ObjectStore"
              "jetstream.nats.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "streams" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta2.Stream" "streams" "Stream" "jetstream.nats.io"
              "v1beta2"
          )
        );
        default = { };
      };
      "streamTemplates" = mkOption {
        description = "";
        type = (
          types.attrsOf (
            submoduleForDefinition "jetstream.nats.io.v1beta1.StreamTemplate" "streamtemplates" "StreamTemplate"
              "jetstream.nats.io"
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
        name = "consumers";
        group = "jetstream.nats.io";
        version = "v1beta1";
        kind = "Consumer";
        attrName = "consumers";
      }
      {
        name = "streams";
        group = "jetstream.nats.io";
        version = "v1beta1";
        kind = "Stream";
        attrName = "streams";
      }
      {
        name = "streamtemplates";
        group = "jetstream.nats.io";
        version = "v1beta1";
        kind = "StreamTemplate";
        attrName = "streamTemplates";
      }
      {
        name = "accounts";
        group = "jetstream.nats.io";
        version = "v1beta2";
        kind = "Account";
        attrName = "accounts";
      }
      {
        name = "consumers";
        group = "jetstream.nats.io";
        version = "v1beta2";
        kind = "Consumer";
        attrName = "consumers";
      }
      {
        name = "keyvalues";
        group = "jetstream.nats.io";
        version = "v1beta2";
        kind = "KeyValue";
        attrName = "keyValues";
      }
      {
        name = "objectstores";
        group = "jetstream.nats.io";
        version = "v1beta2";
        kind = "ObjectStore";
        attrName = "objectStores";
      }
      {
        name = "streams";
        group = "jetstream.nats.io";
        version = "v1beta2";
        kind = "Stream";
        attrName = "streams";
      }
    ];

    resources = {
      "jetstream.nats.io"."v1beta2"."Account" = mkAliasDefinitions options.resources."accounts";
      "jetstream.nats.io"."v1beta2"."Consumer" = mkAliasDefinitions options.resources."consumers";
      "jetstream.nats.io"."v1beta2"."KeyValue" = mkAliasDefinitions options.resources."keyValues";
      "jetstream.nats.io"."v1beta2"."ObjectStore" = mkAliasDefinitions options.resources."objectStores";
      "jetstream.nats.io"."v1beta2"."Stream" = mkAliasDefinitions options.resources."streams";
      "jetstream.nats.io"."v1beta1"."StreamTemplate" =
        mkAliasDefinitions
          options.resources."streamTemplates";

    };

    # make all namespaced resources default to the
    # application's namespace
    defaults = [
      {
        group = "jetstream.nats.io";
        version = "v1beta1";
        kind = "Consumer";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "jetstream.nats.io";
        version = "v1beta1";
        kind = "Stream";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "jetstream.nats.io";
        version = "v1beta1";
        kind = "StreamTemplate";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "jetstream.nats.io";
        version = "v1beta2";
        kind = "Account";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "jetstream.nats.io";
        version = "v1beta2";
        kind = "Consumer";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "jetstream.nats.io";
        version = "v1beta2";
        kind = "KeyValue";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "jetstream.nats.io";
        version = "v1beta2";
        kind = "ObjectStore";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
      {
        group = "jetstream.nats.io";
        version = "v1beta2";
        kind = "Stream";
        default.metadata.namespace = lib.mkDefault config.namespace;
      }
    ];
  };
}
