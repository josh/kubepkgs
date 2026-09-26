{
  lib,
  stdenvNoCC,
  cacert,
  gh,
  git,
  jq,
  nix,
  python3,
}:
let
  python = python3.withPackages (ps: [ ps.click ]);
in
stdenvNoCC.mkDerivation {
  name = "update-json-snapshots";

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python.interpreter}"
      cat "${./update-json-snapshots.py}"
    ) >$out/bin/update-json-snapshots
    substituteInPlace $out/bin/update-json-snapshots \
      --replace-fail '@cacert@' '${cacert}/etc/ssl/certs/ca-bundle.crt' \
      --replace-fail '@gh@' '${gh}/bin/gh' \
      --replace-fail '@git@' '${git}/bin/git' \
      --replace-fail '@jq@' '${jq}/bin/jq' \
      --replace-fail '@nix@' '${nix}/bin/nix'
    chmod +x $out/bin/update-json-snapshots
  '';

  meta = {
    description = "Refresh vendored JSON payload snapshots in this repo";
    license = lib.licenses.mit;
    mainProgram = "update-json-snapshots";
    platforms = lib.platforms.all;
  };
}
