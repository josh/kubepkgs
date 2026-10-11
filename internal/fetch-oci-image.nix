{
  lib,
  callPackage,
  stdenvNoCC,
  jq,
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

  indexDigest = parsed.digest;
  indexFile = fetchManifest parsed.digest;

  manifestDigests = parsed.manifests;
  manifestFiles = builtins.map fetchManifest parsed.manifests;

  blobDigests = parsed.blobs;
  blobFiles = builtins.map (digest: fetchOciBlob { inherit imageName digest; }) parsed.blobs;

  nativeBuildInputs = [ jq ];

  buildCommand = ''
    mkdir -p "$out/blobs/sha256"
    printf '%s' '{"imageLayoutVersion":"1.0.0"}' >"$out/oci-layout"

    ln -s "$indexFile" "$out/blobs/sha256/''${indexDigest#sha256:}"
    for i in "''${!manifestDigests[@]}"; do
      ln -s "''${manifestFiles[i]}" "$out/blobs/sha256/''${manifestDigests[i]#sha256:}"
    done
    for i in "''${!blobDigests[@]}"; do
      ln -s "''${blobFiles[i]}" "$out/blobs/sha256/''${blobDigests[i]#sha256:}"
    done

    jq --compact-output \
      --arg digest "$indexDigest" \
      --arg tag "${finalAttrs.passthru.imageTag}" \
      --argjson size "$(stat -c %s "$indexFile")" \
      '{
        schemaVersion: 2,
        mediaType: "application/vnd.oci.image.index.v1+json",
        manifests: [{
          mediaType: (.mediaType // "application/vnd.oci.image.index.v1+json"),
          digest: $digest,
          size: $size,
          annotations: {"org.opencontainers.image.ref.name": $tag}
        }]
      }' "$indexFile" >"$out/index.json"
  '';

  passthru = {
    inherit imageName;
    imageDigest = parsed.digest;
    imageTag = builtins.substring 0 32 (
      builtins.convertHash {
        hash = lib.strings.removePrefix "sha256:" parsed.digest;
        hashAlgo = "sha256";
        toHashFormat = "nix32";
      }
    );
    ociImage = {
      inherit pname imageName;
      inherit (parsed) tag digest;
      lock = builtins.toString lock;
    };

    copyTo = writeShellApplication {
      name = "copy-to";
      runtimeInputs = [ skopeo ];
      text = ''
        if [ $# -lt 1 ]; then
          echo "usage: copy-to REF [skopeo copy flags...]" >&2
          exit 1
        fi
        ref=$1
        shift
        exec skopeo copy --insecure-policy --all --preserve-digests \
          "oci:${finalAttrs.finalPackage}:${finalAttrs.passthru.imageTag}" "docker://$ref" "$@"
      '';
    };
  };

  meta = {
    description = "${imageName} container image mirror";
    platforms = lib.platforms.all;
  }
  // meta;
})
