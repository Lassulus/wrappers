{
  wlib,
  lib,
  ...
}:
wlib.wrapModule (
  { config, wlib, ... }:
  let
    tomlFmt = config.pkgs.formats.toml { };
  in
  {
    options = {
      settings = lib.mkOption {
        inherit (tomlFmt) type;
        default = { };
        description = ''
          Configuration of tealdeer.
          See <tealdeer-rs.github.io/tealdeer/config.html>
        '';
        extraFlags = lib.mkOption {
          type = lib.types.attrsOf lib.types.unspecified; # TODO add list handling
          default = { };
          description = "Extra flags to pass to tealdeer";
        };
      };
    };
    config.flags = {
      "--config-path" = tomlFmt.generate "tealdeer.toml" config.settings;
    }
    // config.extraFlags;
    config.package = lib.mkDefault config.pkgs.tealdeer;
  }
)
