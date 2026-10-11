{
  lib,
  stdenvNoCC,
  jq,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cloudflare-ips";
  version = "0-unstable-2026-10-11";

  __structuredAttrs = true;

  src = ./cloudflare-ips.json;

  buildCommand = ''install -m 444 "$src" "$out"'';

  passthru.data = builtins.fromJSON (builtins.readFile ./cloudflare-ips.json);

  passthru.jsonSnapshot = {
    inherit (finalAttrs) pname version;
    url = "https://api.cloudflare.com/client/v4/ips";
    filter = "{ipv4_cidrs: .result.ipv4_cidrs, ipv6_cidrs: .result.ipv6_cidrs}";
    file = builtins.toString ./cloudflare-ips.nix;
    snapshot = builtins.toString ./cloudflare-ips.json;
  };

  passthru.tests = {
    json =
      runCommand "test-cloudflare-ips-json"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status . ${finalAttrs.finalPackage} >/dev/null
          jq --exit-status 'has("ipv4_cidrs") and has("ipv6_cidrs")' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    cidrs =
      runCommand "test-cloudflare-ips-cidrs"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          readarray -t cidrs < <(jq --raw-output '.ipv4_cidrs[], .ipv6_cidrs[]' ${finalAttrs.finalPackage})
          [ "''${#cidrs[@]}" -gt 0 ]
          if printf '%s\n' "''${cidrs[@]}" | grep --invert-match --extended-regexp '^[0-9a-f:.]+(/[0-9]+)?$'; then
            exit 1
          fi
          touch $out
        '';

    ipv4 =
      runCommand "test-cloudflare-ips-ipv4"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status '(.ipv4_cidrs | length > 0) and all(.ipv4_cidrs[]; test("^[0-9.]+/[0-9]+$"))' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    data =
      runCommand "test-cloudflare-ips-data"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
          env.expectedFile = builtins.toFile "cloudflare-ips-expected.json" (
            builtins.toJSON finalAttrs.passthru.data
          );
        }
        ''
          jq --exit-status --null-input --slurpfile expected "$expectedFile" --slurpfile actual ${finalAttrs.finalPackage} '$expected == $actual' >/dev/null
          touch $out
        '';
  };

  meta = {
    description = "Cloudflare published IP ranges";
    homepage = "https://www.cloudflare.com/ips/";
    platforms = lib.platforms.all;
  };
})
