{
  wlib,
  lib,
  ...
}:
wlib.wrapModule (
  { config, wlib, ... }:
  let
    iniFormat = config.pkgs.formats.iniWithGlobalSection { };
    iniAtomType = iniFormat.lib.types.atom;

    settings = iniFormat.generate "mako-settings" { globalSection = config.settings; };
  in
  {
    options = {
      settings = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.oneOf [
            iniAtomType
            (lib.types.attrsOf iniAtomType)
          ]
        );
        default = { };
        description = ''
          Configuration settings for mako. Can include both global settings and sections.
          All available options can be found here:
          <https://github.com/emersion/mako/blob/master/doc/mako.5.scd>.
        '';
      };
      extraFlags = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified; # TODO add list handling
        default = { };
        description = "Extra flags to pass to mako.";
      };
    };

    config.flagSeparator = "=";
    config.flags = {
      "--config" = settings;
    }
    // config.extraFlags;

    config.package = lib.mkDefault config.pkgs.mako;
  }
)
