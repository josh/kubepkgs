{
  lib,
  callPackage,
  crane,
  dockerTools,
  jq,
  runCommand,
  skopeo,
  writeShellApplication,
}:
{
  name,
  contents ? [ ],
  config ? { },
  extraCommands ? "",
  fakeRootCommands ? "",
  fakeNss ? dockerTools.fakeNss,
  testScript ? null,
  meta ? { },
}:
let
  testOciImage = callPackage ./test-oci-image.nix { };

  stream = dockerTools.streamLayeredImage {
    inherit
      name
      config
      extraCommands
      fakeRootCommands
      ;

    contents = contents ++ [ fakeNss ];
  };

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
      ''
        ${stream} | skopeo copy --insecure-policy --tmpdir "$TMPDIR" --dest-compress-format gzip \
          docker-archive:/dev/stdin "oci:$out:${stream.imageTag}"

        manifest=$(jq -r '.manifests[0].digest' "$out/index.json")
        config=$(jq -r .config.digest "$out/blobs/sha256/''${manifest#sha256:}")
        jq --compact-output --slurpfile config "$out/blobs/sha256/''${config#sha256:}" \
          '.manifests[0].platform = ($config[0] | {architecture, os})' \
          "$out/index.json" >index.json
        install -m 444 index.json "$out/index.json"
      '';

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
