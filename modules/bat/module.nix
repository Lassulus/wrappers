{
  config,
  lib,
  wlib,
  ...
}:
{
  _class = "wrapper";
  options = {
    "bat-config" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = "bat configuration file.";
    };
  };

  config.env.BAT_CONFIG_PATH = toString config."bat-config".path;

  config.package = config.pkgs.bat;
  config.meta.maintainers = [ lib.maintainers.randomdude ];
}
