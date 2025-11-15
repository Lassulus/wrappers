{
  config,
  lib,
  wlib,
  ...
}:
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
      type = lib.types.attrsOf lib.types.unspecified;
      default = { };
      description = "Extra flags to pass to fuzzel.";
    };
    "fuzzel.ini" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = iniFmt.generate "fuzzel.ini" config.settings;
    };
  };
  config.flagSeparator = "=";
  config.flags = {
    "--config" = config."fuzzel.ini".path;
  }
  // config.extraFlags;
  config.package = lib.mkDefault config.pkgs.fuzzel;
  config.meta.maintainers = [ lib.maintainers.zimward ];
  config.meta.platforms = lib.platforms.linux;
}
