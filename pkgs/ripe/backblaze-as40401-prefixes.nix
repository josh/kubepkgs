{
  lib,
  stdenvNoCC,
  jq,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "backblaze-as40401-prefixes";
  version = "0-unstable-2026-09-26";

  __structuredAttrs = true;

  src = ./backblaze-as40401-prefixes.json;

  buildCommand = ''install -m 444 "$src" "$out"'';

  passthru.data = builtins.fromJSON (builtins.readFile ./backblaze-as40401-prefixes.json);

  passthru.jsonSnapshot = {
    inherit (finalAttrs) pname version;
    url = "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS40401";
    filter = "{resource: .data.resource, prefixes: [.data.prefixes[].prefix] | sort}";
    file = builtins.toString ./backblaze-as40401-prefixes.nix;
    snapshot = builtins.toString ./backblaze-as40401-prefixes.json;
  };

  passthru.tests = {
    json =
      runCommand "test-backblaze-as40401-prefixes-json"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status . ${finalAttrs.finalPackage} >/dev/null
          jq --exit-status '.resource == "40401" and (.prefixes | length > 0)' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    cidrs =
      runCommand "test-backblaze-as40401-prefixes-cidrs"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          readarray -t cidrs < <(jq --raw-output '.prefixes[]' ${finalAttrs.finalPackage})
          [ "''${#cidrs[@]}" -gt 0 ]
          if printf '%s\n' "''${cidrs[@]}" | grep --invert-match --extended-regexp '^[0-9a-f:.]+(/[0-9]+)?$'; then
            exit 1
          fi
          touch $out
        '';

    ipv4 =
      runCommand "test-backblaze-as40401-prefixes-ipv4"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status '[.prefixes[] | select(contains(":") | not)] | length > 0' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    data =
      runCommand "test-backblaze-as40401-prefixes-data"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
          env.expectedFile = builtins.toFile "backblaze-as40401-prefixes-expected.json" (
            builtins.toJSON finalAttrs.passthru.data
          );
        }
        ''
          jq --exit-status --null-input --slurpfile expected "$expectedFile" --slurpfile actual ${finalAttrs.finalPackage} '$expected == $actual' >/dev/null
          touch $out
        '';
  };

  meta = {
    description = "BGP prefixes announced by Backblaze AS40401, via RIPEstat";
    homepage = "https://stat.ripe.net/AS40401";
    platforms = lib.platforms.all;
  };
})
