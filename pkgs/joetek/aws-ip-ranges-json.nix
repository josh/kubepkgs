{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  jq,
  nix-update-script,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "aws-ip-ranges-json";
  version = "0-unstable-2026-09-23";

  src = fetchFromGitHub {
    owner = "joetek";
    repo = "aws-ip-ranges-json";
    rev = "8daf81dec91c85410c4c0d3407b94a3585e9d335";
    hash = "sha256-I5apksHSoANOG4+0jpDwupAtw2A5QhbKP8zKhuyWKp0=";
  };

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp ./ip-ranges*.json $out/

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  passthru.tests = {
    json =
      runCommand "test-aws-ip-ranges-json-json"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          readarray -t files < <(find ${finalAttrs.finalPackage} -name 'ip-ranges*.json')
          [ "''${#files[@]}" -gt 0 ]
          jq --exit-status . "''${files[@]}" >/dev/null
          jq --exit-status 'has("syncToken") and has("createDate") and has("prefixes") and has("ipv6_prefixes")' ${finalAttrs.finalPackage}/ip-ranges.json >/dev/null
          touch $out
        '';

    cidrs =
      runCommand "test-aws-ip-ranges-json-cidrs"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          for f in ip-ranges.json ip-ranges-cloudfront.json ip-ranges-ec2.json ip-ranges-s3.json; do
            [ -s "${finalAttrs.finalPackage}/$f" ]
          done
          readarray -t cidrs < <(jq --raw-output '.prefixes[].ip_prefix, .ipv6_prefixes[].ipv6_prefix' ${finalAttrs.finalPackage}/ip-ranges*.json)
          [ "''${#cidrs[@]}" -gt 0 ]
          if printf '%s\n' "''${cidrs[@]}" | grep --invert-match --extended-regexp '^[0-9a-f:.]+(/[0-9]+)?$'; then
            exit 1
          fi
          touch $out
        '';
  };

  meta = {
    description = "History of AWS published IP ranges, split per service";
    homepage = "https://github.com/joetek/aws-ip-ranges-json";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
  };
})
