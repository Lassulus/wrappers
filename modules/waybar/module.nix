{
  config,
  wlib,
  lib,
  ...
}:
let
  jsonFmt = config.pkgs.formats.json { };
  conf = jsonFmt.generate "waybar-config" config.settings;
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      type = jsonFmt.type;
      default = { };
      description = ''
        Waybar configuration settings.
        See <https://github.com/Alexays/Waybar/wiki/Configuration>
      '';
      example = {
        position = "top";
        height = 30;
        layer = "top";
        modules-center = [ ];
        modules-left = [
          "niri/workspaces"
          "sway/workspaces"
        ];
      };
    };
    style = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = "CSS style for Waybar.";
    };
  };

  config.package = lib.mkDefault config.pkgs.waybar;
  config.flags = {
    "--config" = conf;
    "--style" = config.style.path;
  };
  config.meta.maintainers = [
    {
      name = "turbio";
      github = "turbio";
      githubId = 1428207;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
