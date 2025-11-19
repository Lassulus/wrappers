{
  config,
  lib,
  wlib,
  ...
}:
{
  _class = "wrapper";
  options = {
    "kitty.conf" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = ''
        Configuration for kitty.
        The fast, feature-rich, GPU based terminal emulator.
      '';
    };
  };

  config.flags = {
    "--config" = config."kitty.conf".path;
  };

  config.package = config.pkgs.kitty;

  config.meta.maintainers = [
    {
      name = "adeci";
      github = "adeci";
      githubId = 80290157;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
