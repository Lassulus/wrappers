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
        fzf = {
          enable = lib.mkEnableOption "fzf";
          package = lib.mkOption {
            type = lib.types.package;
            default = config.pkgs.fzf;
          };
        };
        atuin = {
          enable = lib.mkEnableOption "atuin";
          package = lib.mkOption {
            type = lib.types.package;
            default = config.pkgs.atuin;
          };
        };
        oh-my-posh = {
          enable = lib.mkEnableOption "oh-my-posh";
          package = lib.mkOption {
            type = lib.types.package;
            default = config.pkgs.oh-my-posh;
          };
        };
        zoxide = {
          enable = lib.mkEnableOption "zoxide";
          package = lib.mkOption {
            type = lib.types.package;
            default = config.pkgs.zoxide;
          };
          flags = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
          };
          description = "adds fzf to zsh without integrating solely so that zoxide can use it for reverse searching, use this if you dont want to integrate fzf with your shell for history, but want it for zoxide";
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

    ".zshrc" =
      let
        zoxide-flags = lib.concatStringsSep " " cfg.integrations.zoxide.flags;
      in
      lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.content = builtins.concatStringsSep "\n" [
          "# KeyMap"
          (
            if cfg.keyMap == "viins" then
              "bindkey -a"
            else if cfg.keyMap == "vicmd" then
              "bindkey -v"
            else
              "bindkey -e"
          )
          (if cfg.autocd then "setopt autocd" else "")

          "# Aliases"

          (lib.concatMapAttrsStringSep "\n" (k: v: ''alias -- ${k}="${v}"'') cfg.shellAliases)

          "# integrations"
          (if cfg.integrations.fzf.enable then "eval $(fzf --zsh)" else "")
          (if cfg.integrations.atuin.enable then ''eval "$(atuin init zsh)"'' else "")
          (if cfg.integrations.oh-my-posh.enable then ''eval "$(oh-my-posh init zsh)"'' else "")
          (if cfg.integrations.zoxide.enable then ''eval "$(zoxide init zsh ${zoxide-flags})"'' else "")

          "# History"

          "HISTSIZE=${toString cfg.history.size}"
          "HISTSAVE=${toString cfg.history.save}"

          "#Extra Content"

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
    extraPackages =
      let
        ing = cfg.integrations;
      in
      lib.optional ing.fzf.enable ing.fzf.package
      ++ lib.optional ing.atuin.enable ing.atuin.package
      ++ lib.optional ing.zoxide.enable ing.zoxide.package
      ++ lib.optional ing.oh-my-posh.enable ing.oh-my-posh.package;

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
