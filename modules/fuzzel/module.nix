{ config, lib, ... }:
let
  iniFmt = config.pkgs.formats.ini { };
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      type = iniFmt.type;
      default = { };
      description = ''
        Configuration of fuzzel.
        See {manpage}`fuzzel.ini(5)`
      '';
    };
    extraFlags = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified; # TODO add list handling
      default = { };
      description = "Extra flags to pass to fuzzel.";
    };
  };
  config.flagSeparator = "=";
  config.flags = {
    "--config" = iniFmt.generate "fuzzel.ini" config.settings;
  }
  // config.extraFlags;
  config.package = lib.mkDefault config.pkgs.fuzzel;
  config.meta.maintainers = [ lib.maintainers.zimward ];
  config.meta.platforms = lib.platforms.linux;
}
