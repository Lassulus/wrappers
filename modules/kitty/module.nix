{
  config,
  lib,
  wlib,
  ...
}:

let
  kittyKeyValueFormat = config.pkgs.formats.keyValue {
    listsAsDuplicateKeys = true;
    mkKeyValue = lib.generators.mkKeyValueDefault { } " ";
  };
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      type = kittyKeyValueFormat.type;
      default = { };
      description = ''
        Configuration for kitty.
        The fast, feature-rich, GPU based terminal emulator.
      '';
    };

    extraSettings = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra lines appended to the config file.
        This can be used to maintain order for settings.
      '';
    };

    "kitty.conf" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path =
        let
          fileName = "kitty.conf";
          base = kittyKeyValueFormat.generate fileName config.settings;
        in
        if config.extraSettings != "" then
          config.pkgs.concatText fileName [
            base
            (config.pkgs.writeText "extraSettings" config.extraSettings)
          ]
        else
          base;
      description = ''
        Raw configuration for kitty.
      '';
    };
  };

  config.flags = {
    "--config" = toString config."kitty.conf".path;
  };

  config.package = config.pkgs.kitty;

  config.meta.maintainers = [
    {
      name = "adeci";
      github = "adeci";
      githubId = 80290157;
    }
    {
      name = "Lenny.";
      github = "LennyPenny";
      githubId = 4027243;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
