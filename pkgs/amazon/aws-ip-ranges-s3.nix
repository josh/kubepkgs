{
  lib,
  stdenvNoCC,
  jq,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "aws-ip-ranges-s3";
  version = "0-unstable-2026-09-26";

  __structuredAttrs = true;

  src = ./aws-ip-ranges-s3.json;

  buildCommand = ''install -m 444 "$src" "$out"'';

  passthru.data = builtins.fromJSON (builtins.readFile ./aws-ip-ranges-s3.json);

  passthru.jsonSnapshot = {
    inherit (finalAttrs) pname version;
    url = "https://ip-ranges.amazonaws.com/ip-ranges.json";
    filter = ''{prefixes: [.prefixes[] | select(.service == "S3")], ipv6_prefixes: [.ipv6_prefixes[] | select(.service == "S3")]}'';
    file = builtins.toString ./aws-ip-ranges-s3.nix;
    snapshot = builtins.toString ./aws-ip-ranges-s3.json;
  };

  passthru.tests = {
    json =
      runCommand "test-aws-ip-ranges-s3-json"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status . ${finalAttrs.finalPackage} >/dev/null
          jq --exit-status 'has("prefixes") and has("ipv6_prefixes")' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    cidrs =
      runCommand "test-aws-ip-ranges-s3-cidrs"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          readarray -t cidrs < <(jq --raw-output '.prefixes[].ip_prefix, .ipv6_prefixes[].ipv6_prefix' ${finalAttrs.finalPackage})
          [ "''${#cidrs[@]}" -gt 0 ]
          if printf '%s\n' "''${cidrs[@]}" | grep --invert-match --extended-regexp '^[0-9a-f:.]+(/[0-9]+)?$'; then
            exit 1
          fi
          touch $out
        '';

    service =
      runCommand "test-aws-ip-ranges-s3-service"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status 'all(.prefixes[], .ipv6_prefixes[]; .service == "S3")' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    region =
      runCommand "test-aws-ip-ranges-s3-region"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status '[.prefixes[] | select(.region == "us-east-1")] | length > 0' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    data =
      runCommand "test-aws-ip-ranges-s3-data"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
          env.expectedFile = builtins.toFile "aws-ip-ranges-s3-expected.json" (
            builtins.toJSON finalAttrs.passthru.data
          );
        }
        ''
          jq --exit-status --null-input --slurpfile expected "$expectedFile" --slurpfile actual ${finalAttrs.finalPackage} '$expected == $actual' >/dev/null
          touch $out
        '';
  };

  meta = {
    description = "AWS published S3 IP ranges, filtered from ip-ranges.json";
    homepage = "https://docs.aws.amazon.com/vpc/latest/userguide/aws-ip-ranges.html";
    platforms = lib.platforms.all;
  };
})
