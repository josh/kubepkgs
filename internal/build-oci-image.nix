{
  lib,
  callPackage,
  crane,
  dockerTools,
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
        nativeBuildInputs = [ skopeo ];
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
