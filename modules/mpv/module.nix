{
  config,
  lib,
  wlib,
  ...
}:
{
  _class = "wrapper";
  options = {
    scripts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Scripts to add to mpv via override.";
    };
    "mpv.input" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
    };
    "mpv.conf" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
    };
  };
  config.flagSeparator = "=";
  config.flags = {
    "--input-conf" = config."mpv.input".path;
    "--include" = config."mpv.conf".path;
  };
  config.package = (
    config.pkgs.mpv.override {
      scripts = config.scripts;
    }
  );
  config.meta.maintainers = [ lib.maintainers.lassulus ];
}
