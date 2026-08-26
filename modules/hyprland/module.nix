{
  config,
  lib,
  wlib,
  ...
}:
{
  _class = "wrapper";
  options = {
    "hyprland.conf" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = ''
        for basic setup of one hyprland.conf file
      '';
    };

    "hyprland.lua" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = ''
        for basic setup of one hyprland.lua file in lua
      '';
    };

    settings.configLang = lib.mkOption {
      type = lib.types.string;
      default.content = "hyprlang"; # Set it to hyprlang by default since people using this module were using that and I don't wanna break theiir config.
      description = " can by set to lua if needed (recommmended)"; # hyprlang is about to be deprecated
    };
  };

  config.flags =
    let
      cfg = config.settings;
    in
    {
      "--config" = (
        if config.configLang == "hyprlang" then cfg."hyprland.conf".path else cfg."hyprland.lua".path
      );
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
