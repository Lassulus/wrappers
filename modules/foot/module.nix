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
    extraFlags = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = { };
      description = "Extra flags to pass to foot.";
    };
    "foot.ini" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      description = "foot.init configuration file.";
      default.path = iniFmt.generate "foot.ini" config.settings;
    };
  };
  config.flags = {
    "--config" = config."foot.ini".path;
  }
  // config.extraFlags;
  config.package = lib.mkDefault config.pkgs.foot;
  config.meta.maintainers = [ lib.maintainers.randomdude ];
  config.meta.platforms = lib.platforms.linux;
}
