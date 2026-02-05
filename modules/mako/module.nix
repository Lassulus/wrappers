{
  config,
  lib,
  wlib,
  ...
}:
let
  iniFormat = config.pkgs.formats.iniWithGlobalSection { listsAsDuplicateKeys = true; };
  iniAtomType = iniFormat.lib.types.atom;
in
{
  _class = "wrapper";
  options = {
    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = iniFormat.generate "mako-settings" {
        globalSection = lib.filterAttrs (name: value: builtins.typeOf value != "set") config.settings;
        sections = lib.filterAttrs (name: value: builtins.typeOf value == "set") config.settings;
      };
    };

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
  };
  config = {
    flagSeparator = "=";
    flags = {
      "--config" = toString config.configFile.path;
    };
    package = config.pkgs.mako;
    filesToPatch = [
      "share/dbus-1/services/fr.emersion.mako.service"
      "share/systemd/user/mako.service"
    ];
    meta = {
      maintainers = [
        {
          name = "altacountbabi";
          github = "altacountbabi";
          githubId = 82091823;
        }
      ];
      platforms = lib.platforms.linux;
    };
  };
}
