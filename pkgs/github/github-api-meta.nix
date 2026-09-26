{
  lib,
  stdenvNoCC,
  jq,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "github-api-meta";
  version = "0-unstable-2026-09-25";

  __structuredAttrs = true;

  src = ./github-api-meta.json;

  buildCommand = ''install -m 444 "$src" "$out"'';

  passthru.data = builtins.fromJSON (builtins.readFile ./github-api-meta.json);

  passthru.jsonSnapshot = {
    inherit (finalAttrs) pname version;
    url = "https://api.github.com/meta";
    file = builtins.toString ./github-api-meta.nix;
    snapshot = builtins.toString ./github-api-meta.json;
  };

  passthru.tests = {
    json =
      runCommand "test-github-api-meta-json"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          jq --exit-status . ${finalAttrs.finalPackage} >/dev/null
          jq --exit-status 'has("verifiable_password_authentication") and has("ssh_key_fingerprints") and has("domains")' ${finalAttrs.finalPackage} >/dev/null
          touch $out
        '';

    cidrs =
      runCommand "test-github-api-meta-cidrs"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
        }
        ''
          readarray -t cidrs < <(jq --raw-output '.hooks[], .web[], .api[], .git[], .pages[], .actions[]' ${finalAttrs.finalPackage})
          [ "''${#cidrs[@]}" -gt 0 ]
          if printf '%s\n' "''${cidrs[@]}" | grep --invert-match --extended-regexp '^[0-9a-f:.]+(/[0-9]+)?$'; then
            exit 1
          fi
          touch $out
        '';

    data =
      runCommand "test-github-api-meta-data"
        {
          __structuredAttrs = true;
          nativeBuildInputs = [ jq ];
          env.expectedFile = builtins.toFile "github-api-meta-expected.json" (
            builtins.toJSON finalAttrs.passthru.data
          );
        }
        ''
          jq --exit-status --null-input --slurpfile expected "$expectedFile" --slurpfile actual ${finalAttrs.finalPackage} '$expected == $actual' >/dev/null
          touch $out
        '';
  };

  meta = {
    description = "Snapshot of GitHub's api.github.com/meta endpoint";
    homepage = "https://docs.github.com/en/rest/meta/meta";
    platforms = lib.platforms.all;
  };
})
