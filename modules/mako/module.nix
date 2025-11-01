{
  wlib,
  lib,
  ...
}:
wlib.wrapModule (
  { config, wlib, ... }:
  let
    generateConfig =
      config:
      let
        formatValue = v: if builtins.isBool v then if v then "true" else "false" else toString v;

        globalSettings = lib.filterAttrs (n: v: !(lib.isAttrs v)) config;
        sectionSettings = lib.filterAttrs (n: v: lib.isAttrs v) config;

        globalLines = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (k: v: "${k}=${formatValue v}") globalSettings
        );

        formatSection =
          name: attrs:
          "\n[${name}]\n"
          + lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${formatValue v}") attrs);

        sectionLines = lib.concatStringsSep "\n" (lib.mapAttrsToList formatSection sectionSettings);
      in
      if sectionSettings != { } then globalLines + "\n" + sectionLines + "\n" else globalLines + "\n";

    iniFormat = config.pkgs.formats.ini { };
    iniAtomType = iniFormat.lib.types.atom;

    settings = config.pkgs.writeText "mako-settings" (generateConfig config.settings);
  in
  {
    options = {
      settings = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.oneOf [
            iniAtomType
            (lib.types.attrsOf iniAtomType)
          ]
        );
        default = { };
        description = ''
          Configuration settings for mako. Can include both global settings and sections.
          All available options can be found here:
          <https://github.com/emersion/mako/blob/master/doc/mako.5.scd>.
        '';
      };
      extraFlags = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified; # TODO add list handling
        default = { };
        description = "Extra flags to pass to mako.";
      };
    };

    config.flagSeparator = "=";
    config.flags = {
      "--config" = settings;
    }
    // config.extraFlags;

    config.package = lib.mkDefault config.pkgs.mako;
  }
)
