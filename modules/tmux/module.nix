{
  config,
  wlib,
  lib,
  ...
}:
{
  _class = "wrapper";
  options = {
    "tmux.conf" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      description = ''
        Configuration file for tmux
        See <https://github.com/tmux/tmux/wiki>
      '';
    };
  };

  config = {
    package = config.pkgs.tmux;
    flags = {
      "-f" = toString config."tmux.conf".path;
    };

    meta = {
      maintainers = [
        {
          name = "Skyler Oakeson";
          github = "skyler-oakeson";
        }
      ];
    };
  };
}
