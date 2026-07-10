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
      description = ''
        Noctalia Settings
        See <https://docs.noctalia.dev/v5/>
      '';
      default = { };
    };
    "config.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = tomlFmt.generate "noctalia-config" config.settings;
    };
  };

  config = {
    # package needs to be specified manually
    # package = ...
    env = {
      NOCTALIA_CONFIG_HOME = toString (
        config.pkgs.linkFarm "noctalia-config" [
          {
            name = "noctalia/config.toml";
            path = config."config.toml".path;
          }
        ]
      );
    };
    meta = {
      maintainers = [
        {
          # waiting to become a nixpkgs maintainer
          github = "kruemmelspalter";
          githubId = 54735589;
          name = "kruemmelspalter";
          email = "kruemmelspalter@kruemmelspalter.org";
          matrix = "@kruemmelspalter:kruemmelspalter.org";
          keys = [ { fingerprint = "28F5 4BD4 73F1 7495 24BF  F4BD 4F4A 2EFA E386 71C8"; } ];
        }
      ];
      platforms = lib.platforms.linux;
    };
  };
}
