{
  wlib,
  lib,
  ...
}:
wlib.wrapModule (
  {config, ...}: let
    cfg = config.settings;
  in {
    options = {
      settings = {
        keyMap = lib.mkOption {
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
        ".zshrc" = lib.mkOption {
          type = wlib.types.file config.pkgs;
          default = let
            aliasStr = builtins.concatStringsSep "\n" (
              lib.mapAttrsToList (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}")
              cfg.shellAliases
            );
          in {
            path = builtins.concatStringsSep "\n" [
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
      };
    };

    config = let
      RC = config.settings.".zshrc";

      zshConfigDir = config.pkgs.linkFarmFromDrvs "zsh-config-directory" [
        RC
      ];
    in {
      package = config.pkgs.zsh;
      env.Z_DOT_DIR = "${zshConfigDir}";
    };
  }
)
