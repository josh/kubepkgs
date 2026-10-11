{
  lib,
  callPackage,
  stdenvNoCC,
  crane,
  skopeo,
  writeShellApplication,
}:
{
  imageName,
  lock,
  pname ? "${baseNameOf imageName}-index",
  meta ? { },
}:
let
  fetchOciBlob = callPackage ./fetch-oci-blob.nix { };

  parsed = builtins.fromJSON (builtins.readFile lock);

  # builtins.toJSON is canonical, so this matches the digest update-oci-images computes.
  indexJSON = builtins.toJSON parsed.index;
  indexDigest = "sha256:${builtins.hashString "sha256" indexJSON}";
  digest =
    if indexDigest == parsed.digest then
      indexDigest
    else
      throw "${lock}: index serializes to ${indexDigest}, not ${parsed.digest}";

  imageTag = builtins.substring 0 32 (
    builtins.convertHash {
      hash = lib.strings.removePrefix "sha256:" digest;
      hashAlgo = "sha256";
      toHashFormat = "nix32";
    }
  );

  fetchManifest =
    digest:
    fetchOciBlob {
      inherit imageName digest;
      manifest = true;
    };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit pname;
  version = parsed.tag;

  __structuredAttrs = true;

  inherit digest;
  indexFile = builtins.toFile "oci-manifest-${builtins.substring 7 16 digest}" indexJSON;
  layoutIndex = builtins.toJSON {
    schemaVersion = 2;
    mediaType = "application/vnd.oci.image.index.v1+json";
    manifests = [
      {
        mediaType = parsed.index.mediaType or "application/vnd.oci.image.index.v1+json";
        inherit digest;
        size = builtins.stringLength indexJSON;
        annotations."org.opencontainers.image.ref.name" = imageTag;
      }
    ];
  };

  manifestDigests = parsed.manifests;
  manifestFiles = builtins.map fetchManifest parsed.manifests;

  blobDigests = parsed.blobs;
  blobFiles = builtins.map (digest: fetchOciBlob { inherit imageName digest; }) parsed.blobs;

  buildCommand = ''
    mkdir -p "$out/blobs/sha256"
    printf '%s' '{"imageLayoutVersion":"1.0.0"}' >"$out/oci-layout"
    printf '%s' "$layoutIndex" >"$out/index.json"

    ln -s "$indexFile" "$out/blobs/sha256/''${digest#sha256:}"
    for i in "''${!manifestDigests[@]}"; do
      ln -s "''${manifestFiles[i]}" "$out/blobs/sha256/''${manifestDigests[i]#sha256:}"
    done
    for i in "''${!blobDigests[@]}"; do
      ln -s "''${blobFiles[i]}" "$out/blobs/sha256/''${blobDigests[i]#sha256:}"
    done
  '';

  passthru = {
    inherit imageName imageTag;
    imageDigest = digest;
    inherit (parsed) upstreamDigest;
    ociImage = {
      inherit pname imageName;
      inherit (parsed) tag upstreamDigest;
      lock = builtins.toString lock;
    };

    copyTo = writeShellApplication {
      name = "copy-to";
      runtimeInputs = [
        crane
        skopeo
      ];
      text = ''
        if [ $# -lt 1 ]; then
          echo "usage: copy-to REF [skopeo copy flags...]" >&2
          exit 1
        fi
        ref=$1
        shift
        if [ "$(crane digest "$ref" 2>/dev/null)" = "${digest}" ]; then
          echo "existing manifest: $ref@${digest}" >&2
          exit 0
        fi
        exec skopeo copy --insecure-policy --all --preserve-digests \
          "oci:${finalAttrs.finalPackage}:${imageTag}" "docker://$ref" "$@"
      '';
    };
  };

  meta = {
    description = "${imageName} container image mirror";
    platforms = lib.platforms.all;
  }
  // meta;
})
