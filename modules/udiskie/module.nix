{
  config,
  lib,
  wlib,
  ...
}:
let
  yamlFmt = config.pkgs.formats.yaml { };
in
{
  _class = "wrapper";
  options = {
    "config.yml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = yamlFmt.generate "udiskie-config" config.settings;
      description = ''
        Configuration file for udiskie.
      '';
    };

    settings = lib.mkOption {
      type = yamlFmt.type;
      default = { };
      description = ''
        Udiskie settings
        See <https://github.com/coldfix/udiskie/wiki/Usage#configuration>
      '';
    };
  };

  config.flagSeparator = "=";
  config.flags = {
    "--config" = toString config."config.yml".path;
  };

  config.exePath = "${config.package}/bin/udiskie";
  config.package = config.pkgs.udiskie;

  config.meta.maintainers = [
    {
      name = "altacountbabi";
      github = "altacountbabi";
      githubId = 82091823;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
