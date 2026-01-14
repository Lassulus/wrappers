{
  config,
  lib,
  wlib,
  ...
}: {
  _class = "wrapper";
  options = {
    settings = {
      keyMap = lib.mkOption {
        type = lib.types.enum ["vim" "emacs"];
        description = ''
          keymap for zsh, pick between emacs and vi mode, defaults to emacs mode ( will add viins and vicmd options eventually).
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

      history = {
        saveNoDups = lib.mkOption {
          type = lib.types.bool;
          description = ''
            doesnt save a new line if you type in a command already in the history, defaults to false.
          '';
          default = false;
        };
        expireDuplicatesFirst = lib.mkOption {
          type = lib.types.bool;
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
    };
  };
  config = {
    flagSeparator = "=";
    flags = {
      "--vim" = lib.mkIf (config.keyMap == "vim");
      "--emacs" = lib.mkIf (config.keyMap == "emacs");
      "--histsavenodups" = config.history.saveNoDups;
      "--histexpiredupsfirst" = config.history.expireDuplicatesFirst;
      "--histappend" = config.history.append;
      "--histfindnodups" = config.history.findNoDups;
      "--histignoredups" = config.history.ignoreDups;
      "--histignorespace" = config.history.ignoreSpace;
      "--autocd" = config.autocd;
      "--autolist" = config.completion.enable;
      "--automenu" = config.completion.enable;
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
