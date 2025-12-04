{
  config,
  lib,
  wlib,
  ...
}:
let
  # Generator for swaylock's config format
  # - true booleans: just the key name (e.g., "show-failed-attempts")
  # - false booleans: omitted entirely
  # - other values: key=value
  toSwaylockConf =
    attrs:
    lib.concatStringsSep "\n" (
      lib.concatLists (
        lib.mapAttrsToList (
          name: value: if lib.isBool value then lib.optional value name else [ "${name}=${toString value}" ]
        ) attrs
      )
    );
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.str
          lib.types.int
          lib.types.bool
        ]
      );
      default = { };
      description = ''
        Swaylock configuration options.
        See {manpage}`swaylock(1)` for available options.
      '';
    };
    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = toSwaylockConf config.settings;
      description = "Generated swaylock configuration file.";
    };
  };

  config.flags."--config" = toString config.configFile.path;

  config.package = config.pkgs.swaylock;

  config.meta.maintainers = [
    {
      name = "adeci";
      github = "adeci";
      githubId = 80290157;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
