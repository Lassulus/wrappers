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
      inherit (iniFmt) type;
      default = { };
      description = ''
        Configuration of foot terminal.
        See {manpage}`foot.ini(5)`
      '';
    };
    "foot.ini" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      description = "foot.init configuration file.";
      default.path = iniFmt.generate "foot.ini" config.settings;
    };
  };
  config.flags = {
    "--config" = toString config."foot.ini".path;
  };
  config.package = config.pkgs.foot;
  config.meta.maintainers = [ lib.maintainers.randomdude ];
  config.meta.platforms = lib.platforms.linux;
}
