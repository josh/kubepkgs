{
  description = "@josh's Kubernetes Nix Repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      inherit (nixpkgs) lib;
      eachSystem = lib.attrsets.genAttrs systems;
      addAttrsetPrefix = prefix: lib.attrsets.concatMapAttrs (n: v: { "${prefix}${n}" = v; });

      nixpkgsFor = eachSystem (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ ];
        }
      );

      importPackages =
        pkgs:
        let
          inherit (pkgs) lib;

          callPackage = lib.customisation.callPackageWith (pkgs // { kubepkgs = pkgs' // internalPkgs; });

          internalPkgs = {
            checkKubeImages = args: callPackage ./internal/check-kube-images.nix args;
            fetchhelm = callPackage ./internal/fetchhelm.nix { };
            renderHelmTemplate = args: callPackage ./internal/helm-render-template.nix args;
          };

          packagesFromDirectory =
            directory:
            lib.attrsets.concatMapAttrs (
              name: type:
              let
                filename = lib.path.append directory name;
                isNix = lib.strings.hasSuffix ".nix" name;
                basename = lib.strings.removeSuffix ".nix" name;
              in
              if type == "regular" && isNix then { "${basename}" = callPackage filename { }; } else { }
            ) (builtins.readDir directory);

          pkgs' = lib.attrsets.concatMapAttrs (
            name: type:
            let
              dirname = lib.path.append ./pkgs name;
            in
            if type == "directory" then packagesFromDirectory dirname else { }
          ) (builtins.readDir ./pkgs);
        in
        pkgs';

      mkPackages = pkgs: lib.attrsets.filterAttrs (_: pkg: pkg.meta.available) (importPackages pkgs);

      mkChecks =
        pkgs:
        let
          buildCheckPkg =
            pkg: pkgs.runCommand "${pkg.name}-build" { nativeBuildInputs = [ pkg ]; } "touch $out";
        in
        lib.attrsets.concatMapAttrs (
          pkgName: pkg:
          if (builtins.hasAttr "tests" pkg) then
            (
              {
                "${pkgName}-build" = buildCheckPkg pkg;
              }
              // (addAttrsetPrefix "${pkgName}-tests-" pkg.tests)
            )
          else
            { "${pkgName}-build" = buildCheckPkg pkg; }
        ) (mkPackages pkgs);

      treefmt-nix = eachSystem (system: import ./internal/treefmt.nix nixpkgsFor.${system});
    in
    {
      overlays.default = final: _prev: {
        kubepkgs = importPackages final;
      };

      packages = eachSystem (system: mkPackages nixpkgsFor.${system});

      formatter = eachSystem (system: treefmt-nix.${system}.wrapper);
      checks = eachSystem (
        system:
        {
          formatting = treefmt-nix.${system}.check self;
        }
        // (mkChecks nixpkgsFor.${system})
      );
    };
}
