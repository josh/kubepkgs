{
  lib,
  stdenvNoCC,
  gh,
  git,
  nix,
  python3,
}:
let
  python = python3.withPackages (ps: [ ps.click ]);
in
stdenvNoCC.mkDerivation {
  name = "update-crd-modules";

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python.interpreter}"
      cat "${./update-crd-modules.py}"
    ) >$out/bin/update-crd-modules
    substituteInPlace $out/bin/update-crd-modules \
      --replace-fail '@gh@' '${gh}/bin/gh' \
      --replace-fail '@git@' '${git}/bin/git' \
      --replace-fail '@nix@' '${nix}/bin/nix'
    chmod +x $out/bin/update-crd-modules
  '';

  meta = {
    description = "Regenerate committed CRD modules in this repo";
    license = lib.licenses.mit;
    mainProgram = "update-crd-modules";
    platforms = lib.platforms.all;
  };
}
