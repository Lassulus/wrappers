{
  config,
  lib,
  wlib,
  ...
}:
let
  jsonFmt = config.pkgs.formats.json { };
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      type = jsonFmt.type;
      default = { };
      description = ''
        fastfetch settings
        see <https://github.com/fastfetch-cli/fastfetch/wiki/Configuration>
      '';
    };
    "config.jsonc" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = jsonFmt.generate "fastfetch-config" config.settings;
      description = "fastfetch config file";
    };
  };
  config = {
    package = config.pkgs.fastfetch;
    flags."--config" = "${config."config.jsonc".path}";
    meta.maintainers = [
      {
        name = "holly";
        github = "hollymlem";
        githubId = 35699052;
      }
    ];
  };
}
