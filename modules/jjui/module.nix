{
  config,
  wlib,
  lib,
  ...
}:
let
  tomlFmt = config.pkgs.formats.toml { };
  themes = lib.mapAttrsToList (
    name: value:
    let
      fname = "jjui-theme-${name}";
    in
    {
      name = "themes/${name}.toml";
      path =
        if lib.isString value then config.pkgs.writeText fname value else (tomlFmt.generate fname value);
    }
  ) config.themes;
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
    "config.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = tomlFmt.generate "config.toml" config.settings;
    };
  };
  config = {
    package = config.pkgs.jjui;
    env = {
      JJUI_CONFIG_DIR =
        config.pkgs.linkFarm "jjui-merged-config" [
          {
            name = "config.toml";
            path = config."config.toml".path;
          }
        ]
        ++ themes;
    };
    meta.maintainers = [
      {
        name = "olivia";
        github = "oliviafloof";
        githubId = 35699052;
      }
    ];
  };
}
