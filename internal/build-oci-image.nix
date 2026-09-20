{
  lib,
  callPackage,
  dockerTools,
}:
{
  name,
  contents ? [ ],
  config ? { },
  extraCommands ? "",
  fakeRootCommands ? "",
  fakeNss ? dockerTools.fakeNss,
  testScript ? null,
  meta ? { },
}:
let
  testOciImage = callPackage ./test-oci-image.nix { };

  image = dockerTools.buildLayeredImage {
    inherit
      name
      config
      extraCommands
      fakeRootCommands
      ;

    contents = contents ++ [ fakeNss ];

    compressor = "none";

    meta = {
      platforms = lib.platforms.linux;
    }
    // meta;
  };
in
if testScript == null then
  image
else
  image.overrideAttrs (old: {
    passthru = old.passthru // {
      tests.integration = testOciImage { inherit image testScript; };
    };
  })
