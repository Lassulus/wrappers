{
  config,
  lib,
  wlib,
  ...
}:
let
  cfg = config.settings;
in
{
  _class = "wrapper";
  options = {
    settings = {
      keyMap = lib.mkOption {
        type = lib.types.enum [
          "emacs"
          "viins"
          "vicmd"
        ];
        default = "emacs";
        description = "zsh key map, defaults to emacs mode (bindkey -e).";
      };

      shellAliases = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = { };
        description = "shell aliases (alias -- key=value)";
      };

      autocd = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "cd into a directory just by typing it in";
      };
      integrations = {
        atuin = {
          enable = lib.mkEnableOption {
            type = lib.types.bool;
            default = false;
          };
          package = lib.mkOption {
            type = lib.types.package;
            default = config.pkgs.atuin;
            example = "inputs.self.packages.{pkgs.stdenv.hostPlatform.system}.atuin";
          };
        };
      };

      history = {
        append = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "append history for every new session instead of replacing it";
        };
        expanded = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "save timestamps with history";
        };
        save = lib.mkOption {
          type = lib.types.int;
          default = 10000;
          description = "the number of history lines to save";
        };
        size = lib.mkOption {
          type = lib.types.int;
          default = 10000;
          description = "the number of lines to keep";
        };
        expireDupsFirst = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "remove duplicates in the history first to make room for new commands";
        };
        findNoDups = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "don't display duplicates when doing a history search";
        };
        ignoreAllDups = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "if you run the same command twice, the newer replaces the old one in history, even if its a different output";
        };

        ignoreDups = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "if you run the same command twice, the newer replaces the old one in history, only if it's the same output";
        };
        ignoreSpace = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "a command is not added to history if a space preceeds it";
        };

        saveNoDups = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "don't write duplicates into the history file.";
        };
      };

      env = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = {
          EXAMPLE = "TRUE";
        };
        description = "environment variables to put in .zshenv as an attribute set of strings just like environment.systemVariables";
      };
    };
    extraRC = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "extra stuff to put in .zshrc, gets appended *after* all of the options";
    };

    ".zshrc" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = builtins.concatStringsSep "\n" [
        (
          if cfg.keyMap == "viins" then
            "bindkey -a"
          else if cfg.keyMap == "vicmd" then
            "bindkey -v"
          else
            "bindkey -e"
        )
        (if cfg.autocd then "setopt autocd" else "")
        (lib.concatMapAttrsStringSep "\n" (k: v: ''alias -- ${k}="${v}"'') cfg.shellAliases)
        "HISTSIZE=${toString cfg.history.size}"
        "HISTSAVE=${toString cfg.history.save}"
        (if cfg.integrations.atuin.enable == true then ''eval "$(atuin init zsh)"'' else "")
        config.extraRC
      ];
    };

    ".zshenv" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = builtins.concatStringsSep "\n" [
        (lib.concatMapAttrsStringSep "\n" (k: v: "${k}=${v}") cfg.env)
      ];
    };
  };
  config = {
    package = config.pkgs.zsh;
    flags = {
      "--histfcntllock" = true;
      "--histappend" = cfg.history.append;
      "--histexpiredupsfirst" = cfg.history.expireDupsFirst;
      "--histfindnodups" = cfg.history.findNoDups;
      "--histignorealldups" = cfg.history.ignoreAllDups;
      "--histignoredups" = cfg.history.ignoreDups;
      "--histignorespace" = cfg.history.ignoreSpace;
      "--histsavenodups" = cfg.history.saveNoDups;
      "--histexpand" = cfg.history.expanded;
    };
    extraPackages = [
      (lib.mkIf cfg.integrations.atuin.enable config.pkgs.atuin)
    ];
    env.ZDOTDIR = builtins.toString (
      config.pkgs.linkFarm "zsh-merged-config" [
        {
          name = ".zshrc";
          inherit (config.".zshrc") path;
        }
        {
          name = ".zshenv";
          inherit (config.".zshenv") path;
        }
      ]
    );
    meta.maintainers = [
      {
        name = "mrid22";
        github = "mrid22";
        githubId = 153362027;
      }
    ];
  };
}
