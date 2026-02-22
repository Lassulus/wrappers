{
  wlib,
  lib,
  ...
}:
wlib.wrapModule (
  { config, ... }:
  let
    tomlFmt = config.pkgs.formats.toml { };
  in
  {
    options = {
      settings = lib.mkOption {
        type = tomlFmt.type;
        default = { };
        description = ''
          Yazi configuration for yazi.toml.
          See https://yazi-rs.github.io/docs/configuration/yazi
        '';
      };

      keymap = lib.mkOption {
        type = tomlFmt.type;
        default = { };
        description = ''
          Yazi configuration for keymap.toml.
          See <https://yazi-rs.github.io/docs/configuration/keymap>
        '';
      };

      theme = lib.mkOption {
        type = tomlFmt.type;
        default = { };
        description = ''
          Yazi configuration for theme.toml.
          See <https://yazi-rs.github.io/docs/configuration/theme>
        '';
      };

      extraFlags = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified; # TODO add list handling
        default = { };
        description = "Extra flags to pass to yazi.";
      };
    };

    config =
      let
        settingsToml = tomlFmt.generate "yazi.toml" config.settings;
        keymapToml = tomlFmt.generate "keymap.toml" config.keymap;
        themeToml = tomlFmt.generate "theme.toml" config.theme;

        yaziConfigDir = config.pkgs.linkFarmFromDrvs "yazi-config-directory" [
          settingsToml
          keymapToml
          themeToml
        ];
      in
      {
        flags = config.extraFlags;
        package = lib.mkDefault config.pkgs.yazi;
        env.YAZI_CONFIG_HOME = "${yaziConfigDir}";
      };
  }
)
