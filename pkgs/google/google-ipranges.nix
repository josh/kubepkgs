{
  lib,
  stdenvNoCC,
  jq,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "google-ipranges";
  version = "0-unstable-2026-09-26";

  __structuredAttrs = true;

  src = ./google-ipranges.json;

  buildCommand = ''install -m 444 "$src" "$out"'';

  passthru.data = builtins.fromJSON (builtins.readFile ./google-ipranges.json);

  passthru.jsonSnapshot = {
    inherit (finalAttrs) pname version;
    url = "https://www.gstatic.com/ipranges/goog.json";
    filter = "{prefixes: .prefixes}";
    file = builtins.toString ./google-ipranges.nix;
    snapshot = builtins.toString ./google-ipranges.json;
  };

  passthru.tests = {
    json =
      runCommand "test-google-ipranges-json"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status . ${finalAttrs.finalPackage} >/dev/null
          jq --exit-status 'has("prefixes") and (.prefixes | length > 0)' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    cidrs =
      runCommand "test-google-ipranges-cidrs"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          readarray -t cidrs < <(jq --raw-output '.prefixes[] | .ipv4Prefix // .ipv6Prefix' ${finalAttrs.finalPackage})
          [ "''${#cidrs[@]}" -gt 0 ]
          if printf '%s\n' "''${cidrs[@]}" | grep --invert-match --extended-regexp '^[0-9a-f:.]+(/[0-9]+)?$'; then
            exit 1
          fi
          touch $out
        '';

    ipv4 =
      runCommand "test-google-ipranges-ipv4"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status '[.prefixes[] | select(has("ipv4Prefix"))] | length > 0' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    data =
      runCommand "test-google-ipranges-data"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
          env.expectedFile = builtins.toFile "google-ipranges-expected.json" (
            builtins.toJSON finalAttrs.passthru.data
          );
        }
        ''
          jq --exit-status --null-input --slurpfile expected "$expectedFile" --slurpfile actual ${finalAttrs.finalPackage} '$expected == $actual' >/dev/null
          touch $out
        '';
  };

  meta = {
    description = "Google published IP ranges, including Google Cloud customer ranges";
    homepage = "https://support.google.com/a/answer/10026322";
    platforms = lib.platforms.all;
  };
})
