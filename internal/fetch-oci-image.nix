{
  lib,
  callPackage,
  stdenvNoCC,
}:
{
  imageName,
  lock,
  pname ? "${baseNameOf imageName}-image",
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
stdenvNoCC.mkDerivation {
  inherit pname;
  version = parsed.tag;

  __structuredAttrs = true;

  indexFile = fetchManifest parsed.digest;

  manifestDigests = parsed.manifests;
  manifestFiles = builtins.map fetchManifest parsed.manifests;

  blobDigests = parsed.blobs;
  blobFiles = builtins.map (digest: fetchOciBlob { inherit imageName digest; }) parsed.blobs;

  buildCommand = ''
    mkdir -p "$out/blobs/sha256"
    printf '%s' '{"imageLayoutVersion":"1.0.0"}' >"$out/oci-layout"
    install -m 444 "$indexFile" "$out/index.json"

    for i in "''${!manifestDigests[@]}"; do
      install -m 444 "''${manifestFiles[i]}" "$out/blobs/sha256/''${manifestDigests[i]#sha256:}"
    done

    for i in "''${!blobDigests[@]}"; do
      install -m 444 "''${blobFiles[i]}" "$out/blobs/sha256/''${blobDigests[i]#sha256:}"
    done
  '';

  passthru = {
    inherit imageName;
    imageDigest = parsed.digest;
    ociLayout = true;

    ociImage = {
      inherit pname imageName;
      inherit (parsed) tag digest;
      lock = builtins.toString lock;
    };
  };

  meta = {
    description = "${imageName} container image mirror";
    platforms = lib.platforms.all;
  }
  // meta;
}
