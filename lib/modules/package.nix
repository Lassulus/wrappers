{ lib, ... }:
{
  _file = "lib/modules/package.nix";
  options = {
    pkgs = lib.mkOption {
      description = ''
        The nixpkgs pkgs instance to use.
        We want to have this, so wrapper modules can be system agnostic.
      '';
    };
    package = lib.mkOption {
      type = lib.types.package;
      description = ''
        The base package to wrap.
        This means we inherit all other files from this package
        (like man page, /share, ...)
      '';
    };
    passthru = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Additional attributes to add to the resulting derivation's passthru.
        This can be used to add additional metadata or functionality to the wrapped package.
        This will always contain options, config and settings, so these are reserved names and cannot be used here.
      '';
    };
  };
}
