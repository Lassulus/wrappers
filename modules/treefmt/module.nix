{
  config,
  lib,
  wlib,
  ...
}:
let
  tomlFmt = config.pkgs.formats.toml { };
in
{
  _class = "wrapper";

  options = {
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = tomlFmt.type;
        options = {
          excludes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Global list of paths to exclude. Supports glob.";
          };
          formatter = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                freeformType = tomlFmt.type;
                options = {
                  command = lib.mkOption {
                    type = lib.types.str;
                    description = "Executable name or path obeying the treefmt formatter spec.";
                  };
                  options = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Arguments to pass to the command.";
                  };
                  includes = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = "File patterns to include for formatting. Supports glob.";
                  };
                  excludes = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "File patterns to exclude from formatting.";
                  };
                };
              }
            );
            default = { };
            description = "Set of formatters to use.";
          };
        };
      };
      default = { };
      description = ''
        Structured treefmt configuration written to treefmt.toml.
        See <https://treefmt.com/latest/getting-started/configure/>
      '';
    };

    programs = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        Formatter packages to add to PATH.
      '';
    };

    "treefmt.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = tomlFmt.generate "treefmt.toml" (
        lib.filterAttrsRecursive (_: v: v != null) config.settings
      );
      description = ''
        The generated treefmt.toml configuration file.
      '';
    };
  };

  config.package = config.pkgs.treefmt;

  config.flags = {
    "--config-file" = toString config."treefmt.toml".path;
  };

  config.extraPackages = config.programs;

  config.meta.maintainers = [
    {
      name = "Alexander Kenji Berthold";
      github = "a-kenji";
      githubId = 65275785;
    }
  ];
  config.meta.platforms = lib.platforms.all;
}
