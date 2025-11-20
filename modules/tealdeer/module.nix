{
  config,
  wlib,
  lib,
  ...
}:
let
  tomlFmt = config.pkgs.formats.toml { };
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      inherit (tomlFmt) type;
      default = { };
      description = ''
        Configuration of tealdeer.
        See <tealdeer-rs.github.io/tealdeer/config.html>
      '';
    };
    extraFlags = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified; # TODO add list handling
      default = { };
      description = "Extra flags to pass to tealdeer";
    };
    "tealdeer.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      description = "tealdeer.toml configuration file.";
      default.path = tomlFmt.generate "tealdeer.toml" config.settings;
    };
  };
  config.flags = {
    "--config-path" = config."tealdeer.toml".path;
  }
  // config.extraFlags;
  config.package = lib.mkDefault config.pkgs.tealdeer;
  config.meta.maintainers = [ lib.maintainers.randomdude ];
  config.meta.platforms = lib.platforms.linux;
}
