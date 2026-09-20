{
  lib,
  stdenvNoCC,
  cacert,
  crane,
}:
{
  imageName,
  digest,
  manifest ? false,
}:
stdenvNoCC.mkDerivation {
  name = "oci-${if manifest then "manifest" else "blob"}-${builtins.substring 7 16 digest}";

  outputHashAlgo = "sha256";
  outputHashMode = "flat";
  outputHash = lib.strings.removePrefix "sha256:" digest;
  impureEnvVars = lib.fetchers.proxyImpureEnvVars;

  nativeBuildInputs = [
    cacert
    crane
  ];

  buildCommand = ''
    crane ${if manifest then "manifest" else "blob"} "${imageName}@${digest}" >"$out"
  '';
}
