{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all (system: f system);
      # non-exhaustive list of systems nixpkgs has support for
      defaultSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: f system);
    in
    {
      lib = import ./lib { lib = nixpkgs.lib; };
      wrapperModules = import ./modules.nix {
        lib = nixpkgs.lib;
        wlib = self.lib;
      };
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # Load checks from checks/ directory
          checkFiles = builtins.readDir ./checks;
          importCheck = name: {
            name = nixpkgs.lib.removeSuffix ".nix" name;
            value = import (./checks + "/${name}") {
              inherit pkgs;
              self = self;
            };
          };
          checksFromDir = builtins.listToAttrs (
            map importCheck (
              builtins.filter (name: nixpkgs.lib.hasSuffix ".nix" name) (builtins.attrNames checkFiles)
            )
          );

          # Load checks from modules/**/check.nix
          moduleFiles = builtins.readDir ./modules;
          importModuleCheck =
            name: type:
            let
              checkPath = ./modules + "/${name}/check.nix";
              # Check if current system is in the module's supported platforms
              isSupported = builtins.elem system self.wrapperModules.${name}.meta.platforms;
            in
            if type == "directory" && builtins.pathExists checkPath && isSupported then
              {
                name = "module-${name}";
                value = import checkPath {
                  inherit pkgs;
                  self = self;
                };
              }
            else
              null;
          checksFromModules = builtins.listToAttrs (
            nixpkgs.lib.filter (x: x != null) (nixpkgs.lib.mapAttrsToList importModuleCheck moduleFiles)
          );
        in
        checksFromDir // checksFromModules
      );
      # mdbook documentation for all modules
      packages = defaultSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = nixpkgs.lib;
        in
        {
          mdbook = (
            pkgs.stdenvNoCC.mkDerivation {
              name = "wrappers-mdbook";
              nativeBuildInputs = with pkgs; [
                mdbook
              ];
              srcs = lib.mapAttrsToList (_: v: ((v.apply { inherit pkgs; }).docs.commonMark)) self.wrapperModules;
              names = lib.mapAttrsToList (name: _: name) self.wrapperModules;
              dontUnpack = true;
              dontPatch = true;
              buildPhase = ''
                # echo "[book]" >> book.toml
                # echo "title = \"wrappers\"" >> book.toml
                mdbook init wrappers
                cd wrappers/src
                echo "# Summary" > SUMMARY.md
                names=($names)
                srcs=($srcs)
                for i in "''${!names[@]}"; do
                  cp ''${srcs[$i]} ''${names[$i]}.md

                  echo "- ["''${names[$i]}"](''${names[$i]}.md)" >> SUMMARY.md
                done
                cat SUMMARY.md
                mkdir -p $out
                cd ..
                mdbook build --dest-dir $out
              '';
            }
          );
        }
      );
    };
}
