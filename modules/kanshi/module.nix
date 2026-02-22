{
  config,
  lib,
  wlib,
  ...
}:
{
  _class = "wrapper";
  options = {
    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = ''
        Kanshi configuration file.
        See {manpage}`kanshi(5)` for the configuration format.
      '';
      example = ''
        profile {
          output LVDS-1 disable
          output "Some Company ASDF 4242" mode 1600x900 position 0,0
        }

        profile nomad {
          output LVDS-1 enable scale 2
        }
      '';
    };
  };
  config.flags = {
    "--config" = "${config.configFile.path}";
  };
  config.package = config.pkgs.kanshi;
  config.meta.maintainers = [ lib.maintainers.adeci ];
  config.meta.platforms = lib.platforms.linux;
}
