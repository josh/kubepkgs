{
  description = "@josh's Kubernetes Nix Repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      internal-inputs = builtins.mapAttrs (
        _name: node: builtins.getFlake (builtins.flakeRefToString node.locked)
      ) (builtins.fromJSON (builtins.readFile ./internal/flake.lock)).nodes;

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      inherit (nixpkgs) lib;
      eachSystem = lib.attrsets.genAttrs systems;
      addAttrsetPrefix = prefix: lib.attrsets.concatMapAttrs (n: v: { "${prefix}${n}" = v; });

      importNixpkgs =
        flake: system:
        import flake.outPath {
          inherit system;
          config.allowUnfree = true;
          overlays = [ ];
        };

      importPackages =
        pkgs:
        let
          inherit (pkgs) lib;

          callPackage = lib.customisation.callPackageWith (
            pkgs // { nur.repos.josh = pkgs' // internalPkgs; }
          );

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
        name: pkgs:
        let
          buildCheckPkg =
            pkg: pkgs.runCommand "${pkg.name}-${name}-build" { nativeBuildInputs = [ pkg ]; } "touch $out";
        in
        lib.attrsets.concatMapAttrs (
          pkgName: pkg:
          if (builtins.hasAttr "tests" pkg) then
            (
              {
                "${pkgName}-${name}-build" = buildCheckPkg pkg;
              }
              // (addAttrsetPrefix "${pkgName}-${name}-tests-" pkg.tests)
            )
          else
            { "${pkgName}-${name}-build" = buildCheckPkg pkg; }
        ) (mkPackages pkgs);

      treefmt-nix = eachSystem (import ./internal/treefmt.nix);
    in
    {
      overlays.default = final: prev: {
        nur = (prev.nur or { }) // {
          repos = (prev.nur.repos or { }) // {
            josh = importPackages final;
          };
        };
      };

      packages = eachSystem (system: mkPackages (importNixpkgs nixpkgs system));

      formatter = eachSystem (system: treefmt-nix.${system}.wrapper);
      checks = eachSystem (
        system:
        {
          formatting = treefmt-nix.${system}.check self;
        }
        // (mkChecks "stable" (importNixpkgs internal-inputs.nixpkgs-stable system))
        // (mkChecks "unstable" (importNixpkgs internal-inputs.nixpkgs-unstable system))
      );
    };
}
