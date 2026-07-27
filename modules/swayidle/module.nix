{
  config,
  lib,
  wlib,
  ...
}:
{
  imports = [ wlib.modules.systemd ];

  options = {
    events = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
      description = "Config file for swayidle, see {manpage}`swayidle(1)`";
      example = {
        content = ''
          lock 'pidof gtklock || gtklock'
          timeout 300 'loginctl lock-session'
        '';
      };
    };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      description = "Systemd target to bind to";
    };
  };

  config = {
    package = config.pkgs.swayidle;

    flags."-C" = config.events.path;

    systemd = {
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      wantedBy = [ config.systemdTarget ];
      partOf = [ config.systemdTarget ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = "${config.exePath} -w -C ${config.events.path}";
      };
    };

    meta = {
      maintainers = [ lib.maintainers.bandithedoge ];
      platforms = lib.platforms.linux;
    };
  };
}
