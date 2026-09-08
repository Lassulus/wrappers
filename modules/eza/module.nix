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
    theme = lib.mkOption {
      type = yamlFmt.type;
      default = { };
      description = "See {manpage}`eza_colors-explanation(5)`";
    };
    "theme.yml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = yamlFmt.generate "eza-theme" config.theme;
    };
    extraFiles = lib.mkOption {
      type = lib.types.attrsOf (wlib.types.file config.pkgs);
      default = { };
      description = "Additional files to be placed in the config directory";
    };
  };
  config = {
    extraFiles = { inherit (config) "theme.yml"; };
    env.EZA_CONFIG_DIR = toString (
      config.pkgs.linkFarm "eza-merged-config" (
        lib.mapAttrsToList (name: value: {
          inherit name;
          inherit (value) path;
        }) config.extraFiles
      )
    );
    package = config.pkgs.eza;
    meta = {
      maintainers = [
        {
          name = "holly";
          github = "aquifolly";
          githubId = 35699052;
        }
      ];
    };
  };
}
