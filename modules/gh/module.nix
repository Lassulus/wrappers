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
    settings = lib.mkOption {
      inherit (yamlFmt) type;
      default = {
        version = 1;
      };
      description = "See <https://cli.github.com/manual/gh_config>";
      example = {
        version = 1;
        git_protocol = "ssh";
        telemetry = "disabled";
      };
    };

    extraFiles = lib.mkOption {
      type = lib.types.attrsOf (wlib.types.file config.pkgs);
      default = { };
      description = "Additional files written to the configuration directory";
      example = lib.literalExpression ''
        {
          "hosts.yml".content = builtins.toJSON {
            "github.com".user = "<username>";
          };
        }
      '';
    };
  };

  config = {
    package = lib.mkDefault config.pkgs.gh;

    extraFiles."config.yml" = lib.mkIf (config.settings != null) {
      path = yamlFmt.generate "config.yml" config.settings;
    };

    env.GH_CONFIG_DIR = toString (
      config.pkgs.linkFarm "gh-merged-config" (
        lib.mapAttrsToList (name: value: {
          inherit name;
          inherit (value) path;
        }) config.extraFiles
      )
    );
  };

  meta.maintainers = [ lib.maintainers.bandithedoge ];
}
