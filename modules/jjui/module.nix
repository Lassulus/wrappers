{
  config,
  wlib,
  lib,
  ...
}:
let
  tomlFmt = config.pkgs.formats.toml { };
  themes = lib.mapAttrsToList (name: value: {
    name = "themes/${name}.toml";
    path = value.path;
  }) config.themeFiles;
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      type = tomlFmt.type;
      default = { };
      description = ''
        Configuration of jjui.
        See <https://github.com/idursun/jjui/wiki/Configuration>
      '';
    };
    themes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          tomlFmt.type
          lib.types.lines
        ]
      );
      default = { };
      description = ''
        Themes to add to config.
        See <https://github.com/idursun/jjui/wiki/Themes>
      '';
    };
    themeFiles = lib.mkOption {
      type = lib.types.attrsOf (wlib.types.file config.pkgs);
      default = lib.mapAttrs (
        name: value:
        let
          fname = "jjui-theme-${name}";
        in
        {
          path =
            if lib.isString value then config.pkgs.writeText fname value else (tomlFmt.generate fname value);
        }
      ) config.themes;
    };
    "config.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = tomlFmt.generate "config.toml" config.settings;
    };
  };
  config = {
    package = config.pkgs.jjui;
    env = {
      JJUI_CONFIG_DIR = builtins.toString (
        config.pkgs.linkFarm "jjui-merged-config" (
          [
            {
              name = "config.toml";
              path = config."config.toml".path;
            }
          ]
          ++ themes
        )
      );
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
