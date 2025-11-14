{
  config,
  lib,
  wlib,
  ...
}:
{
  _class = "wrapper";
  options = {
    "env.nu" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
    };
    "config.nu" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
    };
  };

  config.flagSeparator = "=";
  config.flags = {
    "--config" = config."config.nu".path;
    "--env-config" = config."env.nu".path;
  };

  config.package = lib.mkDefault config.pkgs.nushell;

  config.meta.maintainers = [
    {
      name = "altacountbabi";
      github = "altacountbabi";
      githubId = 82091823;
    }
  ];
}
