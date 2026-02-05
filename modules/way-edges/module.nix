{
  config,
  lib,
  wlib,
  ...
}:
let
  jsonFmt = config.pkgs.formats.json { };
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      type = jsonFmt.type;
      default = { };
      description = ''
        way-edges settings
        see <https://github.com/way-edges/way-edges/tree/master/doc/config>
      '';
      example = {
        widgets = [
          {
            namespace = "workspaces";
            monitor = "*";
            edge = "left";
            position = "top";
            layer = "top";
            active-increase = 0;
            default-color = "#1e1e2e";
            focus-color = "#f5c2e7";
            hover-color = "#f5c2e7";
            length = 200;
            preset = {
              type = "niri";
            };
            thickness = 8;
            type = "workspace";
          }
        ];
      };
    };
    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = jsonFmt.generate "way-edges-config" config.settings;
      description = ''
        way-edges config file
        see <https://github.com/way-edges/way-edges/tree/master/doc/config>
      '';
    };
  };
  config = {
    package = config.pkgs.way-edges;
    flags = {
      "--config" = toString config.configFile.path;
    };
    meta.maintainers = [
      {
        name = "holly";
        github = "hollymlem";
        githubId = 35699052;
      }
    ];
  };
}
