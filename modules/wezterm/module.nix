{
  wlib,
  lib,
}:
wlib.wrapModule (
  { config, wlib, ... }:
  {
    options = {
      "wezterm.lua" = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.content = "";
      };
      extraFlags = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified; # TODO add list handling
        default = { };
        description = "Extra flags to pass to wezterm.";
      };
    };

    config.flagSeparator = "=";
    config.flags = {
      "--config-file" = config."wezterm.lua".path;
    }
    // config.extraFlags;

    config.package = lib.mkDefault config.pkgs.wezterm;

    config.meta.maintainers = [
      {
        name = "altacountbabi";
        github = "altacountbabi";
        githubId = 82091823;
      }
    ];
  }
)
