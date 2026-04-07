{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
let
  wlib = import ./lib { inherit lib; };
in
{
  lib = wlib;
  wrapperModules = import ./modules.nix {
    inherit lib wlib;
  };
}
