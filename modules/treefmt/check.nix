{
  pkgs,
  self,
}:
let
  treefmtWrapped =
    (self.wrapperModules.treefmt.apply {
      inherit pkgs;
      settings = {
        formatter.nixfmt = {
          command = "nixpkgs-fmt";
          includes = [ "*.nix" ];
        };
      };
      programs = [ pkgs.nixpkgs-fmt ];
    }).wrapper;
in
pkgs.runCommand "treefmt-test" { } ''
  "${treefmtWrapped}/bin/treefmt" --version | grep -q "treefmt"
  touch $out
''
