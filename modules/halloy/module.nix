{
  config,
  wlib,
  lib,
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
    };
    "config.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = tomlFmt.generate "halloy-config" config.settings;
    };
    extraFiles = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "File name in the halloy config directory";
            };
            file = lib.mkOption {
              type = wlib.types.file config.pkgs;
              description = "File or path to add in the halloy config directory";
            };
          };
        }
      );
      default = [ ];
      description = "Additional files to be placed in the config directory";
    };
  };
  config = {
    env = {
      XDG_CONFIG_HOME = toString (
        config.pkgs.linkFarm "halloy-merged-config" (
          map
            (a: {
              inherit (a) path;
              name = "halloy/" + a.name;
            })
            (
              let
                entry = name: path: { inherit name path; };
              in
              [ (entry "config.toml" config."config.toml".path) ]
              ++ (map (f: {
                inherit (f) name;
                path = f.file.path;
              }) config.extraFiles)
            )
        )
      );
    };
    package = config.pkgs.halloy;
    meta = {
      maintainers = [
        {
          name = "holly";
          github = "hollymlem";
          githubId = 35699052;
        }
      ];
    };
  };
}
