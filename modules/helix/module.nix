{
  config,
  lib,
  wlib,
  ...
}:
let
  tomlFmt = config.pkgs.formats.toml { };
  themes = lib.mapAttrsToList (
    name: value:
    let
      fname = "helix-theme-${name}";
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
      description = ''
        General settings
        See <https://docs.helix-editor.com/configuration.html>
      '';
      default = { };
    };
    extraSettings = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra lines appended to the config file.
        This can be used to maintain order for settings.
      '';
    };
    languages = lib.mkOption {
      type = tomlFmt.type;
      description = ''
        Language specific settings
        See <https://docs.helix-editor.com/languages.html>
      '';
      default = { };
    };
    themes = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          tomlFmt.type
          lib.types.lines
        ]
      );
      description = ''
        Themes to add to config.
        See <https://docs.helix-editor.com/themes.html>
      '';
      default = { };
    };
    ignores = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
      description = ''
        List of paths to be ignored by the file-picker.
        The format is the same as in .gitignore.
      '';
    };
    "config.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path =
        let
          base = tomlFmt.generate "helix-config" config.settings;
        in
        if config.extraSettings != "" then
          config.pkgs.concatText "helix-config" [
            base
            (config.pkgs.writeText "extraSettings" config.extraSettings)
          ]
        else
          base;
    };
    "languages.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = tomlFmt.generate "helix-languages.toml" config.languages;
    };
    ignoreFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = lib.strings.concatLines config.ignores;
    };
  };
  config.package = lib.mkDefault config.pkgs.helix;
  config.env = {
    XDG_CONFIG_HOME = builtins.toString (
      config.pkgs.linkFarm "helix-merged-config" (
        map
          (a: {
            inherit (a) path;
            name = "helix/" + a.name;
          })
          (
            let
              entry = name: path: { inherit name path; };
            in
            [
              (entry "config.toml" config."config.toml".path)
              (entry "languages.toml" config."languages.toml".path)
              (entry "ignore" config.ignoreFile.path)
            ]
            ++ themes
          )
      )
    );
  };
  config.meta.maintainers = [ lib.maintainers.zimward ];
}
