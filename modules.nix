{ wlib, lib }:
lib.mapAttrs' (
  name: type: lib.nameValuePair name (wlib.wrapModule (import ./modules/${name}/module.nix))
) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./modules))
