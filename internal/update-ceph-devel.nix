{
  lib,
  stdenvNoCC,
  cacert,
  git,
  python3,
}:
let
  python = python3.withPackages (ps: [ ps.click ]);
in
stdenvNoCC.mkDerivation {
  name = "update-ceph-devel";

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python.interpreter}"
      cat "${./update-ceph-devel.py}"
    ) >$out/bin/update-ceph-devel
    substituteInPlace $out/bin/update-ceph-devel \
      --replace-fail '@cacert@' '${cacert}/etc/ssl/certs/ca-bundle.crt' \
      --replace-fail '@git@' '${git}/bin/git'
    chmod +x $out/bin/update-ceph-devel
  '';

  meta = {
    description = "Refresh Ceph devel RPM locks from a release series' repodata";
    license = lib.licenses.mit;
    mainProgram = "update-ceph-devel";
    platforms = lib.platforms.all;
  };
}
