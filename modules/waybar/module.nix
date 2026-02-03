{
  config,
  wlib,
  lib,
  ...
}: let
  jsonFmt = config.pkgs.formats.json {};
in {
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      inherit (jsonFmt) type;
      default = {};
      description = ''
        Waybar configuration settings.
        See <https://github.com/Alexays/Waybar/wiki/Configuration>
      '';
      example = {
        position = "top";
        height = 30;
        layer = "top";
        modules-center = [];
        modules-left = [
          "niri/workspaces"
          "sway/workspaces"
        ];
      };
    };
    style = lib.mkOption {
      type = lib.types.lines;
      default = '''';
      description = "css multi-line string";
    };
    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = jsonFmt.generate "waybar-config" config.settings;
      description = ''
        Waybar configuration settings file.
        See <https://github.com/Alexays/Waybar/wiki/Configuration>
      '';
      example.content = ''
        {
          "height": 30,
          "layer": "top",
          "modules-center": [],
          "modules-left": [
            "sway/workspaces",
            "niri/workspaces"
          ]
        }
      '';
    };
    "style.css" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = config.style;
      description = "CSS style for Waybar.";
    };
  };

  config = {
    package = lib.mkDefault config.pkgs.waybar;
    flags = {
      "--config" = toString config.configFile.path;
      "--style" = toString config."style.css".path;
    };
    filesToPatch = [
      "share/systemd/user/waybar.service"
    ];
    meta.maintainers = [
      {
        name = "turbio";
        github = "turbio";
        githubId = 1428207;
      }
    ];
    meta.platforms = lib.platforms.linux;
  };
}
