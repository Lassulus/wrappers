{
  config,
  lib,
  wlib,
  ...
}:
{
  _class = "wrapper";
  options = {
    swayConfig = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = ''
        Sway window manager configuration.
      '';
    };
    extraFlags = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = { };
      description = "Extra flags to pass to sway.";
    };
  };

  config.flags = {
    "--config" = config.swayConfig.path;
  }
  // config.extraFlags;

  config.package = lib.mkDefault config.pkgs.sway;

  config.meta.maintainers = [
    {
      name = "adeci";
      github = "adeci";
      githubId = 80290157;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
