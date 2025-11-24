{
  config,
  lib,
  wlib,
  ...
}:
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
        SwayOSD server configuration.
        See https://github.com/ErikReider/SwayOSD for available options.
      '';
      example = lib.literalExpression ''
        {
          server = {
            max_volume = 150;
            min_brightness = 5;
            top_margin = 0.85;
            show_percentage = true;
          };
        }
      '';
    };
    "config.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = tomlFmt.generate "config.toml" config.settings;
      description = "Generated SwayOSD configuration file.";
    };
    style = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = ''
        CSS stylesheet for SwayOSD appearance.
        See the SwayOSD repository for styling examples.
      '';
    };
  };

  config.flags = {
    "--config" = "${config."config.toml".path}";
    "--style" = if (config.style.content != "") then "${config.style.path}" else false;
  };

  config.exePath = lib.getExe' config.pkgs.swayosd "swayosd-server";

  config.package = config.pkgs.swayosd;

  config.meta.maintainers = [ lib.maintainers.adeci ];
  config.meta.platforms = lib.platforms.linux;
}
