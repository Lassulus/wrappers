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
            "emacs"
            "vicmd"
            "viins"
          ];
        };
        shellAliases = lib.mkOption {
          type = with lib.types; attrsOf str;

          description = ''

            aliases

          '';

          default = {};
        };
      };
    };

    config = let
      RC = builtins.concatStringsSep "\n" [
        # bindkey option
        (
          if cfg.keyMap == "vicmd"
          then "bindkey -a"
          else if cfg.keyMap == "viins"
          then "bindkey -v"
          else "bindkey -e"
        )
        # Aliases
        builtins.concatStringsSep
        "\n"
        (
          lib.mapAttrsToList (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}")
          cfg.shellAliases
        )
      ];
      zshConfigDir = config.pkgs.linkFarmFromDrvs "zsh-config-directory" [
        RC
      ];
    in {
      package = config.pkgs.zsh;
      env.Z_DOT_DIR = "${zshConfigDir}";
      meta = {
        platforms = lib.platforms.linux;
        maintainers = [
          {
            name = "mrid22";
            github = "mrid22";
            githubId = 1428207;
          }
        ];
      };
    };
  }
)
