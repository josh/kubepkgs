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
  version = "0-unstable-2026-09-21";

  src = fetchFromGitHub {
    owner = "BenDutton";
    repo = "gh-api-meta-log";
    rev = "59b0aba45c844e33f9fd6a2664cfed8343903255";
    hash = "sha256-+I/y+3mbKaO8fMvmJ/3oLRkDhVyry5bmCiGKxcgRAuM=";
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
