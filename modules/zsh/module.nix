{
  config,
  lib,
  wlib,
  ...
}: let
  kvFmt = config.pkgs.formats.keyValue {
    listsAsDuplicateKeys = true;
  };
in {
  _class = "wrapper";
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

      autocd = lib.mkOption {
        type = lib.types.bool;
        description = ''
          lets you navigate to a directory just by typing the name/path. defaults to false;
        '';
        default = false;
      };

      completion.enable = lib.mkOption {
        type = lib.types.bool;
        description = ''
          enable completion.
        '';
      };

      shellAliases = lib.mkOption {
        type = with lib.types; attrsOf str;
        description = ''
          aliases
        '';
        default = {};
      };

      history = {
        saveNoDups = lib.mkOption {
          type = lib.types.bool;
          description = ''
            doesn't save a new line if you type in a command already in the history, defaults to false.
          '';
          default = false;
        };
        expireDuplicatesFirst = lib.mkOption {
          type = lib.types.bool;
          description = ''
            expire duplicates first.
          '';
          default = false;
        };
        append = lib.mkOption {
          type = lib.types.bool;
          description = ''
            history from new zsh sessions will be appended to the hist file instead of replacing the old session history, defaults to false.
          '';
          default = false;
        };
        findNoDups = lib.mkOption {
          type = lib.types.bool;
          description = ''
            ignore duplicate history when doing a reverse search.
          '';
          default = false;
        };
        ignoreDups = lib.mkOption {
          type = lib.types.bool;
          description = ''
            sets the --histignoredups flag. TODO: figure out difference with saveNoDups for better docs.
          '';
          default = false;
        };
        ignoreSpace = lib.mkOption {
          description = ''
            lets you omit a command from the history if you put a space before it; defaults to true;
          '';
          default = true;
        };
      };
      ".zshrc" = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default = {
          content = "";
          path = config.pkgs.concatText "zsh-config" [
            (
              if config.settings.keyMap == "vicmd"
              then "bindkey -a"
              else if config.settings.keyMap == "viins"
              then "bindkey -v"
              else "bindkey -e"
            )
            (
              kvFmt.generate "aliases-config" config.settings.shellAliases
            )
          ];
        };
      };
    };
  };
  config = {
    flagSeparator = "=";
    flags = {
      "--histsavenodups" = config.settings.history.saveNoDups;
      "--histexpiredupsfirst" = config.settings.history.expireDuplicatesFirst;
      "--histappend" = config.settings.history.append;
      "--histfindnodups" = config.settings.history.findNoDups;
      "--histignoredups" = config.settings.history.ignoreDups;
      "--histignorespace" = config.settings.history.ignoreSpace;
      "--autocd" = config.settings.autocd;
      "--autolist" = config.settings.completion.enable;
      "--automenu" = config.settings.completion.enable;
    };
    env = {
      Z_DOT_DIR = toString config.settings.".zshrc".path + "..";
    };

    package = config.pkgs.zsh;

    meta.maintainers = [
      {
        name = "mrid22";
        github = config.meta.maintainers.name;
        githubId = 82091823;
      }
    ];
  };
}
