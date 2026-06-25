{
  config,
  lib,
  wlib,
  ...
}:
{
  _class = "wrapper";
  options = {
    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = ''
        I3 Window Manager configuration.
      '';
    };
  };

  config.flags = {
    "--config" = config.configFile.path;
  };

  config.package = config.pkgs.i3;
  config.meta.maintainers = [
    lib.maintainers.randomdude
  ];
  config.meta.platforms = lib.platforms.linux;
}
