{
  config,
  lib,
  wlib,
  ...
}:
let
  iniFmt = config.pkgs.formats.iniWithGlobalSection {
    # from https://github.com/NixOS/nixpkgs/blob/89f10dc1a8b59ba63f150a08f8cf67b0f6a2583e/nixos/modules/programs/foot/default.nix#L11-L29
    listsAsDuplicateKeys = true;
    mkKeyValue =
      with lib.generators;
      mkKeyValueDefault {
        mkValueString =
          v:
          mkValueStringDefault { } (
            if v == true then
              "yes"
            else if v == false then
              "no"
            else if v == null then
              "none"
            else
              v
          );
      } "=";
  };
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      inherit (iniFmt) type;
      default = { };
      description = ''
        Configuration of foot terminal.
        See {manpage}`foot.ini(5)`
      '';
    };
    "foot.ini" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      description = "foot.init configuration file.";
      default.path = iniFmt.generate "foot.ini" {
        globalSection = lib.filterAttrs (name: value: builtins.typeOf value != "set") config.settings;
        sections = lib.filterAttrs (name: value: builtins.typeOf value == "set") config.settings;
      };
    };
  };
  config.flags = {
    "--config" = toString config."foot.ini".path;
  };
  config.package = config.pkgs.foot;
  config.meta.maintainers = [ lib.maintainers.randomdude ];
  config.meta.platforms = lib.platforms.linux;
}
