{
  lib,
  stdenvNoCC,
  jq,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "fastmail-as151847-prefixes";
  version = "0-unstable-2026-10-15";

  __structuredAttrs = true;

  src = ./fastmail-as151847-prefixes.json;

  buildCommand = ''install -m 444 "$src" "$out"'';

  passthru.data = builtins.fromJSON (builtins.readFile ./fastmail-as151847-prefixes.json);

  passthru.jsonSnapshot = {
    inherit (finalAttrs) pname version;
    url = "https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS151847";
    filter = "{resource: .data.resource, prefixes: [.data.prefixes[].prefix] | sort}";
    file = builtins.toString ./fastmail-as151847-prefixes.nix;
    snapshot = builtins.toString ./fastmail-as151847-prefixes.json;
  };

  passthru.tests = {
    json =
      runCommand "test-fastmail-as151847-prefixes-json"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status . ${finalAttrs.finalPackage} >/dev/null
          jq --exit-status '.resource == "151847" and (.prefixes | length > 0)' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    cidrs =
      runCommand "test-fastmail-as151847-prefixes-cidrs"
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
      runCommand "test-fastmail-as151847-prefixes-ipv4"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status '[.prefixes[] | select(contains(":") | not)] | length > 0' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    data =
      runCommand "test-fastmail-as151847-prefixes-data"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
          env.expectedFile = builtins.toFile "fastmail-as151847-prefixes-expected.json" (
            builtins.toJSON finalAttrs.passthru.data
          );
        }
        ''
          jq --exit-status --null-input --slurpfile expected "$expectedFile" --slurpfile actual ${finalAttrs.finalPackage} '$expected == $actual' >/dev/null
          touch $out
        '';
  };

  meta = {
    description = "BGP prefixes announced by Fastmail AS151847, via RIPEstat";
    homepage = "https://stat.ripe.net/AS151847";
    platforms = lib.platforms.all;
  };
})
