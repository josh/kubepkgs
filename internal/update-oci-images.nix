{
  lib,
  stdenvNoCC,
  cacert,
  crane,
  gh,
  git,
  nix,
  python3,
}:
let
  python = python3.withPackages (ps: [ ps.click ]);
in
stdenvNoCC.mkDerivation {
  name = "update-oci-images";

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python.interpreter}"
      cat "${./update-oci-images.py}"
    ) >$out/bin/update-oci-images
    substituteInPlace $out/bin/update-oci-images \
      --replace-fail '@cacert@' '${cacert}/etc/ssl/certs/ca-bundle.crt' \
      --replace-fail '@crane@' '${crane}/bin/crane' \
      --replace-fail '@gh@' '${gh}/bin/gh' \
      --replace-fail '@git@' '${git}/bin/git' \
      --replace-fail '@nix@' '${nix}/bin/nix'
    chmod +x $out/bin/update-oci-images
  '';

  meta = {
    description = "Update pinned OCI image lockfiles in this repo";
    license = lib.licenses.mit;
    mainProgram = "update-oci-images";
    platforms = lib.platforms.all;
  };
}
