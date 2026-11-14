{
  lib,
  callPackage,
  stdenvNoCC,
  crane,
  dockerTools,
  jq,
  runCommand,
  skopeo,
  writeShellApplication,
}:
{
  name,
  fromImage ? null,
  contents ? [ ],
  config ? { },
  extraCommands ? "",
  fakeRootCommands ? "",
  fakeNss ? dockerTools.fakeNss,
  includeNixDB ? false,
  maxLayers ? 100,
  testScript ? null,
  meta ? { },
}:
let
  testOciImage = callPackage ./test-oci-image.nix { };

  arch = stdenvNoCC.hostPlatform.go.GOARCH;

  baseArchive =
    runCommand "${fromImage.name}-${arch}.tar"
      {
        nativeBuildInputs = [
          jq
          skopeo
        ];
      }
      ''
        ref="oci:${fromImage}:${fromImage.imageTag}"
        skopeo --override-os linux --override-arch ${arch} inspect --config "$ref" >config.json
        if ! jq --exit-status '.os == "linux" and .architecture == "${arch}"' config.json >/dev/null; then
          echo "error: ${fromImage.name} has no linux/${arch} image" >&2
          exit 1
        fi
        skopeo --override-os linux --override-arch ${arch} copy --insecure-policy --tmpdir "$TMPDIR" \
          "$ref" "docker-archive:$out"
      '';

  stream = dockerTools.streamLayeredImage (
    {
      inherit
        name
        config
        extraCommands
        fakeRootCommands
        includeNixDB
        maxLayers
        ;

      contents = contents ++ lib.lists.optional (fakeNss != null) fakeNss;
    }
    // lib.attrsets.optionalAttrs (fromImage != null) {
      fromImage = baseArchive;
    }
  );

  image =
    runCommand "${name}-oci"
      {
        nativeBuildInputs = [
          jq
          skopeo
        ];
        passthru = {
          inherit (stream) imageName imageTag;
        };
        meta = {
          platforms = lib.platforms.linux;
        }
        // meta;
      }
      (
        ''
          ${stream} | skopeo copy --insecure-policy --tmpdir "$TMPDIR" --dest-compress-format gzip \
            docker-archive:/dev/stdin "oci:$out:${stream.imageTag}"

          manifest=$(jq -r '.manifests[0].digest' "$out/index.json")
          config=$(jq -r .config.digest "$out/blobs/sha256/''${manifest#sha256:}")
          jq --compact-output --slurpfile config "$out/blobs/sha256/''${config#sha256:}" \
            '.manifests[0].platform = ($config[0] | {architecture, os})' \
            "$out/index.json" >index.json
          install -m 444 index.json "$out/index.json"
        ''
        + lib.strings.optionalString (fromImage != null) ''

          skopeo inspect --config "docker-archive:${baseArchive}" >base-config.json
          dropped=$(jq --raw-output --slurpfile image "$out/blobs/sha256/''${config#sha256:}" '
            def set: . != null and . != "" and . != [];
            .config as $base
            | [ "User", "WorkingDir", "Entrypoint", "Cmd"
                | select(($base[.] | set) and ($image[0].config[.] | set | not)) ]
            | join(", ")
          ' base-config.json)
          if [ -n "$dropped" ]; then
            echo "error: ${name} leaves $dropped unset, but ${fromImage.imageName} sets them;" \
              "streamLayeredImage carries over only Env from fromImage, so set them in config" >&2
            exit 1
          fi
        ''
      );

  copyTo = writeShellApplication {
    name = "copy-to";
    runtimeInputs = [ crane ];
    text = ''
      if [ $# -lt 1 ]; then
        echo "usage: copy-to REF [crane push flags...]" >&2
        exit 1
      fi
      ref=$1
      shift
      exec crane push "${image}" "$ref" "$@"
    '';
  };
in
image.overrideAttrs (old: {
  passthru =
    old.passthru
    // {
      inherit copyTo;
    }
    // lib.attrsets.optionalAttrs (testScript != null) {
      tests.integration = testOciImage { inherit image testScript; };
    };
})
