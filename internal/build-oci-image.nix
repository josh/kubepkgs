{
  lib,
  dockerTools,
}:
{
  name,
  contents ? [ ],
  config ? { },
  extraCommands ? "",
  fakeRootCommands ? "",
  fakeNss ? dockerTools.fakeNss,
  meta ? { },
}:
dockerTools.buildLayeredImage {
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
}
