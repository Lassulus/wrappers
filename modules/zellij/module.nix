{
  config,
  wlib,
  lib,
  ...
}:

{
  options = {
    settings = lib.mkOption {
      type = wlib.types.file config.pkgs;
      description = ''
        Settings in KDL format
        See <https://zellij.dev/documentation/configuration.html>
      '';
    };
  };

  config = {
    package = lib.mkDefault config.pkgs.zellij;
    env = {
      ZELLIJ_CONFIG_FILE = builtins.toString config.settings.path;
    };

    meta = {
      maintainers = [
        lib.maintainers.dav-wolff
      ];
    };
  };
}
