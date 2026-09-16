{
  lib,
  stdenvNoCC,
  cacert,
  crane,
  gh,
  git,
  kubernetes-helm,
  nix,
  python3,
}:
let
  python = python3.withPackages (ps: [
    ps.click
    ps.pyyaml
  ]);
in
stdenvNoCC.mkDerivation {
  name = "update-helm-charts";

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python.interpreter}"
      cat "${./update-helm-charts.py}"
    ) >$out/bin/update-helm-charts
    substituteInPlace $out/bin/update-helm-charts \
      --replace-fail '@cacert@' '${cacert}/etc/ssl/certs/ca-bundle.crt' \
      --replace-fail '@crane@' '${crane}/bin/crane' \
      --replace-fail '@gh@' '${gh}/bin/gh' \
      --replace-fail '@git@' '${git}/bin/git' \
      --replace-fail '@helm@' '${kubernetes-helm}/bin/helm' \
      --replace-fail '@nix-hash@' '${nix}/bin/nix-hash' \
      --replace-fail '@nix@' '${nix}/bin/nix'
    chmod +x $out/bin/update-helm-charts
  '';

  meta = {
    description = "Update pinned Helm chart versions and hashes in this repo";
    license = lib.licenses.mit;
    mainProgram = "update-helm-charts";
    platforms = lib.platforms.all;
  };
}
