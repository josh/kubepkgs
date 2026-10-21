{
  lib,
  stdenvNoCC,
  jq,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "fastly-ips";
  version = "0-unstable-2026-10-21";

  __structuredAttrs = true;

  src = ./fastly-ips.json;

  buildCommand = ''install -m 444 "$src" "$out"'';

  passthru.data = builtins.fromJSON (builtins.readFile ./fastly-ips.json);

  passthru.jsonSnapshot = {
    inherit (finalAttrs) pname version;
    url = "https://api.fastly.com/public-ip-list";
    filter = "{addresses: .addresses, ipv6_addresses: .ipv6_addresses}";
    file = builtins.toString ./fastly-ips.nix;
    snapshot = builtins.toString ./fastly-ips.json;
  };

  passthru.tests = {
    json =
      runCommand "test-fastly-ips-json"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status . ${finalAttrs.finalPackage} >/dev/null
          jq --exit-status 'has("addresses") and has("ipv6_addresses")' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    cidrs =
      runCommand "test-fastly-ips-cidrs"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          readarray -t cidrs < <(jq --raw-output '.addresses[], .ipv6_addresses[]' ${finalAttrs.finalPackage})
          [ "''${#cidrs[@]}" -gt 0 ]
          if printf '%s\n' "''${cidrs[@]}" | grep --invert-match --extended-regexp '^[0-9a-f:.]+(/[0-9]+)?$'; then
            exit 1
          fi
          touch $out
        '';

    ipv4 =
      runCommand "test-fastly-ips-ipv4"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status '(.addresses | length > 0) and all(.addresses[]; test("^[0-9.]+/[0-9]+$"))' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    data =
      runCommand "test-fastly-ips-data"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
          env.expectedFile = builtins.toFile "fastly-ips-expected.json" (
            builtins.toJSON finalAttrs.passthru.data
          );
        }
        ''
          jq --exit-status --null-input --slurpfile expected "$expectedFile" --slurpfile actual ${finalAttrs.finalPackage} '$expected == $actual' >/dev/null
          touch $out
        '';
  };

  meta = {
    description = "Fastly published IP ranges";
    homepage = "https://www.fastly.com/documentation/reference/api/utils/public-ip-list/";
    platforms = lib.platforms.all;
  };
})
