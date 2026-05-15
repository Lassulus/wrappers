{
  config,
  lib,
  wlib,
  ...
}:
let
  yamlFmt = config.pkgs.formats.yaml { };
in
{
  _class = "wrapper";

  options = {
    basePackage = lib.mkPackageOption config.pkgs.python3Packages "beets" {
      example = lib.literalExpression ''
        pkgs.python3Packages.beets.override {
          pluginOverrides = {
            beatport.enable = false;
          };
        }
      '';
    };

    settings = lib.mkOption {
      inherit (yamlFmt) type;
      default = { };
      description = ''
        See <https://beets.io/reference/config/>
      '';
      example = {
        directory = "/music";
        library = "/music/library.db";
        plugins = [
          "chroma"
          "fetchart"
        ];
      };
    };

    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = yamlFmt.generate "beets-config" config.settings;
      description = ''
        Configuration of beets
      '';
    };

    extraPlugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = ''
        Attrset mapping beets plugin names to the corresponding package.

        Plugins must be manually enabled in the configuration,
        see <https://beets.readthedocs.io/en/stable/plugins/index.html>
      '';
      example = lib.literalExpression ''
        {
          alternatives = pkgs.python3Packages.beets-alternatives;
        }
      '';
    };
  };

  config = {
    package = config.basePackage.override (
      lib.optionalAttrs (config.extraPlugins != { }) {
        pluginOverrides = lib.mapAttrs (_: pkg: {
          enable = true;
          propagatedBuildInputs = [ pkg ];
        }) config.extraPlugins;
      }
    );

    flags."--config" = config.configFile.path;

    meta = {
      maintainers = [ lib.maintainers.bandithedoge ];
      platforms = with lib.platforms; linux ++ darwin;
    };
  };
}
