{
  pkgs ? import <nixpkgs> { },
}:
let
  lib = pkgs.lib;
  wlib = import ./lib { inherit lib; };
in
{
  lib = wlib;
  wrapperModules = import ./modules.nix {
    inherit lib wlib;
  };
}
