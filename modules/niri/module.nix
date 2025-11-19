{
  config,
  wlib,
  lib,
  ...
}:
{
  _class = "wrapper";
  options = {
    "config.kdl" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = ''
        Configuration file for Niri.
        See <https://github.com/YaLTeR/niri/wiki/Configuration:-Introduction>
      '';
      example = ''
        input {
          keyboard {
              numlock
          }

          touchpad {
              tap
              natural-scroll
          }
        }
      '';
    };
  };
  config.filesToPatch = [
    "share/applications/*.desktop"
    "share/systemd/user/niri.service"
  ];
  config.package = config.pkgs.niri;
  config.env = {
    NIRI_CONFIG = toString config."config.kdl".path;
  };
  config.meta.maintainers = [
    {
      name = "turbio";
      github = "turbio";
      githubId = 1428207;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
