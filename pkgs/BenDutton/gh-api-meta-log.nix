{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  jq,
  nix-update-script,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gh-api-meta-log";
  version = "0-unstable-2026-09-18";

  src = fetchFromGitHub {
    owner = "BenDutton";
    repo = "gh-api-meta-log";
    rev = "29d24bb15bc4212b85fbdb37c77b37219ce8f461";
    hash = "sha256-PvPxTw6nFowQJN6T7o3lAVtVOmfwZHrZVoStcyidJiY=";
  };

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp meta.json $out/

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  passthru.tests = {
    json =
      runCommand "test-gh-api-meta-log-json"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status . ${finalAttrs.finalPackage}/meta.json >/dev/null
          jq --exit-status 'has("verifiable_password_authentication") and has("ssh_key_fingerprints") and has("domains")' ${finalAttrs.finalPackage}/meta.json >/dev/null
          touch $out
        '';

    cidrs =
      runCommand "test-gh-api-meta-log-cidrs"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          readarray -t cidrs < <(jq --raw-output '.hooks[], .web[], .api[], .git[], .pages[], .actions[]' ${finalAttrs.finalPackage}/meta.json)
          [ "''${#cidrs[@]}" -gt 0 ]
          if printf '%s\n' "''${cidrs[@]}" | grep --invert-match --extended-regexp '^[0-9a-f:.]+(/[0-9]+)?$'; then
            exit 1
          fi
          touch $out
        '';
  };

  meta = {
    description = "Hourly snapshots of GitHub's api.github.com/meta endpoint";
    homepage = "https://github.com/BenDutton/gh-api-meta-log";
    platforms = lib.platforms.all;
  };
})
