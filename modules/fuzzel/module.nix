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
    "fuzzel.ini" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = iniFmt.generate "fuzzel.ini" config.settings;
    };
  };
  config.flagSeparator = "=";
  config.flags = {
    "--config" = toString config."fuzzel.ini".path;
  };
  config.package = config.pkgs.fuzzel;
  config.meta.maintainers = [ lib.maintainers.zimward ];
  config.meta.platforms = lib.platforms.linux;
}
