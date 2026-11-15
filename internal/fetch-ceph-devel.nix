{
  lib,
  stdenvNoCC,
  callPackage,
  fetchurl,
  libarchive,
}:
{
  pname,
  series,
  el,
  lock,
  meta ? { },
}:
let
  parsed = builtins.fromJSON (builtins.readFile lock);
  arch = stdenvNoCC.hostPlatform.uname.processor;
  rpm =
    name:
    fetchurl {
      url = "https://download.ceph.com/rpm-${parsed.version}/el${el}/${arch}/${name}-${parsed.version}-0.el${el}.${arch}.rpm";
      hash = parsed.hashes.${arch}.${name};
    };
in
stdenvNoCC.mkDerivation {
  inherit pname;
  inherit (parsed) version;

  nativeBuildInputs = [ libarchive ];

  # The .so links point at the libraries the Ceph image ships, so they dangle here;
  # buildCommand skips the fixup phase that would reject them.
  buildCommand = ''
    mkdir $out
    bsdtar -xf ${rpm "librados-devel"} -C $out ./usr/include ./usr/lib64
    bsdtar -xf ${rpm "libradosstriper-devel"} -C $out ./usr/include ./usr/lib64
  '';

  passthru.updateScript = [
    (lib.meta.getExe (callPackage ./update-ceph-devel.nix { }))
    "--lock"
    (lib.path.removePrefix ../. lock)
    "--series"
    "https://download.ceph.com/rpm-${series}/el${el}"
  ];

  meta = {
    homepage = "https://ceph.io";
    license = lib.licenses.lgpl21;
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  }
  // meta;
}
