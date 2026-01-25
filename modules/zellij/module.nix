{
  config,
  wlib,
  lib,
  ...
}:

{
  options = {
    "config.kdl" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      description = ''
        Settings in KDL format
        See <https://zellij.dev/documentation/configuration.html>
      '';
    };
  };

  config = {
    package = config.pkgs.zellij;
    env = {
      ZELLIJ_CONFIG_FILE = builtins.toString config."config.kdl".path;
    };

    meta = {
      maintainers = [
        lib.maintainers.dav-wolff
      ];
    };
  };
}
