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
        Sway window manager configuration.
      '';
    };
  };

  config.flags = {
    "--config" = config.configFile.path;
  };

  config.package = config.pkgs.sway;

  config.meta.maintainers = [
    {
      name = "adeci";
      github = "adeci";
      githubId = 80290157;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
