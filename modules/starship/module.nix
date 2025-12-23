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
      type = tomlFmt.type;
      default = { };
      description = "Starship configuration as a Nix attribute set. See https://starship.rs/config/";
      example = {
        add_newline = false;
        character = {
          success_symbol = "[>](bold green)";
          error_symbol = "[x](bold red)";
        };
        directory = {
          truncation_length = 3;
        };
      };
    };

    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = toString (tomlFmt.generate "starship.toml" config.settings);
      description = "The starship configuration file.";
    };
  };

  config = {
    package = config.pkgs.starship;
    env.STARSHIP_CONFIG = config.configFile.path;
    meta.maintainers = [
      {
        name = "adeci";
        github = "adeci";
        githubId = 80290157;
      }
    ];
    meta.platforms = lib.platforms.all;
  };
}
