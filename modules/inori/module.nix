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
      description = ''
        Configuration of inori.
        See <https://github.com/eshrh/inori/blob/master/CONFIGURATION.md>
      '';
    };
    "config.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      # TODO add a pure toTOML function
      default.path = tomlFmt.generate "config.toml" config.settings;
      description = "inori configuration file.";
    };
  };
  config = {
    env.XDG_CONFIG_HOME = "${config.pkgs.linkFarm ([
      {
        name = "inori/config.toml";
        inherit (config."config.toml") path;
      }
    ])}";
    package = config.pkgs.inori;
    meta = {
      maintainers = [
        {
          name = "holly";
          github = "hollymlem";
          githubId = 35699052;
        }
      ];
    };
  };
}
