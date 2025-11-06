{
  config,
  lib,
  wlib,
  ...
}:
{
  _class = "wrapper";
  options = {
    "btop.conf" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = ''
        Configuration for btop.
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = { };
      description = "Extra flags to pass to btop.";
    };
  };

  config.flags = {
    "--config" = config."btop.conf".path;
  }
  // config.extraFlags;

  config.package = lib.mkDefault config.pkgs.btop;

  config.meta.maintainers = [
    {
      name = "adeci";
      github = "adeci";
      githubId = 80290157;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
