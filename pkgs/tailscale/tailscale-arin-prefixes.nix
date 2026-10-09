{
  lib,
  stdenvNoCC,
  jq,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "tailscale-arin-prefixes";
  version = "0-unstable-2026-10-09";

  __structuredAttrs = true;

  src = ./tailscale-arin-prefixes.json;

  buildCommand = ''install -m 444 "$src" "$out"'';

  passthru.data = builtins.fromJSON (builtins.readFile ./tailscale-arin-prefixes.json);

  passthru.jsonSnapshot = {
    inherit (finalAttrs) pname version;
    url = "https://rdap.arin.net/registry/entity/TAILS";
    filter = "{resource: .handle, prefixes: [.networks[].cidr0_cidrs[] | ((.v4prefix // .v6prefix) + \"/\" + (.length | tostring)) | ascii_downcase] | sort}";
    file = builtins.toString ./tailscale-arin-prefixes.nix;
    snapshot = builtins.toString ./tailscale-arin-prefixes.json;
  };

  passthru.tests = {
    json =
      runCommand "test-tailscale-arin-prefixes-json"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status . ${finalAttrs.finalPackage} >/dev/null
          jq --exit-status '.resource == "TAILS" and (.prefixes | length > 0)' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    cidrs =
      runCommand "test-tailscale-arin-prefixes-cidrs"
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
      runCommand "test-tailscale-arin-prefixes-ipv4"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status '[.prefixes[] | select(contains(":") | not)] | length > 0' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    data =
      runCommand "test-tailscale-arin-prefixes-data"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
          env.expectedFile = builtins.toFile "tailscale-arin-prefixes-expected.json" (
            builtins.toJSON finalAttrs.passthru.data
          );
        }
        ''
          jq --exit-status --null-input --slurpfile expected "$expectedFile" --slurpfile actual ${finalAttrs.finalPackage} '$expected == $actual' >/dev/null
          touch $out
        '';
  };

  meta = {
    description = "Networks registered to Tailscale (ARIN org TAILS), via ARIN RDAP";
    homepage = "https://rdap.arin.net/registry/entity/TAILS";
    platforms = lib.platforms.all;
  };
})
