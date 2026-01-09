{
  config,
  lib,
  wlib,
  ...
}:
{
  _class = "wrapper";
  options = {
   "hypr.conf" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = ''
        for basic setup of one hypr.conf file
      '';
    };
  };

  config.flags = {
    "--config" = config."hypr.conf".path;
  };

  config.package = config.pkgs.hyprland;

  config.meta.maintainers = [
    {
      name = "PeDro0210";
      github = "PeDro0210";
      githubId = 123851480;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
