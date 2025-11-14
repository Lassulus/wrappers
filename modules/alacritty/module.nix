{ config, lib, ... }:
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
        Configuration of alacritty.
        See {manpage}`alacritty(5)` or <https://alacritty.org/config-alacritty.html>
      '';
    };
    extraFlags = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified; # TODO add list handling
      default = { };
      description = "Extra flags to pass to alacritty.";
    };
  };
  config.flags = {
    "--config-file" = tomlFmt.generate "alacritty.toml" config.settings;
  }
  // config.extraFlags;
  config.package = lib.mkDefault config.pkgs.alacritty;
  config.meta.maintainers = [ lib.maintainers.zimward ];
}
