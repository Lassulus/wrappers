{
  wlib,
  lib,
  ...
}:
wlib.wrapModule (
  {config, ...}: let
    tomlFmt = config.pkgs.formats.toml {};
  cfg = config.settigs;
  in {
    options = {
      settings = {
        keymap = lib.mkOption {
          type = lib.types.enum [
            "viins"
            "emacs"
            "vicmd"
          ];
          description = ''
            keymap for zsh, pick between emacs vi, and vicmd, defaults to emacs mode.
          '';
          default = "emacs";
        };
      };
       ".zshrc" = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default = let
          aliasStr = builtins.concatStringsSep "\n" (
            lib.mapAttrsToList (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}")
            cfg.shellAliases
          );
        in {
          content = builtins.concatStringsSep "\n" [
            (
              if cfg.keyMap == "vicmd"
              then "bindkey -a"
              else if cfg.keyMap == "viins"
              then "bindkey -v"
              else "bindkey -e"
            )
            aliasStr
          ];
        };
    };

    config = let
      RC = config.settings.".zshrc";
      keymapToml = tomlFmt.generate "keymap.toml" config.keymap;
      themeToml = tomlFmt.generate "theme.toml" config.theme;

      yaziConfigDir = config.pkgs.linkFarmFromDrvs "zsh-config-directory" [
        RC
        keymapToml
        themeToml
      ];
    in {
      flags = config.extraFlags;
      package = config.pkgs.zsh;
      env.Z_DOT_DIR = "${yaziConfigDir}";
    };
  }
)
