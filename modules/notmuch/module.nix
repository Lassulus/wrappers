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
      default = {
        database = {
          path = "Maildir";
          mail_root = "Maildir";
        };
      };
    };
    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = toString (iniFmt.generate "notmuch.ini" config.settings);
    };
  };
  config.package = config.pkgs.notmuch;
  config.env.NOTMUCH_CONFIG = config.configFile.path;
  config.meta.maintainers = [ lib.maintainers.lassulus ];
}
