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
        Structured git-cliff configuration written to cliff.toml.
        See <https://git-cliff.org/docs/configuration>
      '';
    };

    "cliff.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = tomlFmt.generate "cliff.toml" config.settings;
      description = ''
        The generated cliff.toml configuration file.
      '';
    };
  };

  config.package = config.pkgs.git-cliff;

  config.flags = {
    "--config" = toString config."cliff.toml".path;
  };

  config.meta.maintainers = [
    {
      name = "Alexander Kenji Berthold";
      github = "a-kenji";
      githubId = 65275785;
    }
  ];
  config.meta.platforms = lib.platforms.all;
}
