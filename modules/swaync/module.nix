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

  imports = [ wlib.modules.systemd ];

  options = {
    configOptions = lib.mkOption {
      type = jsonFmt.type;
      default = { };
      description = ''
        SwayNotificationCenter configuration file.
        See {manpage}`swaync(5)`
      '';
    };
    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = jsonFmt.generate "swaync-config" config.configOptions;
    };
    "style.css" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = "";
    };
    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      description = "Systemd unit to bind to";
    };
  };

  config.package = config.pkgs.swaynotificationcenter;

  config.flags = {
    "--config" = config.configFile.path;
    "--style" = config."style.css".path;
  };

  config.meta.maintainers = [
    lib.maintainers.randomdude
  ];
  config.meta.platforms = lib.platforms.linux;

  config.systemd = {
    partOf = [ config.systemdTarget ];
    after = [ config.systemdTarget ];
    wantedBy = [ config.systemdTarget ];
    unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
    serviceConfig = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${config.exePath} --config ${config.configFile.path} --style ${config."style.css".path}";
      Restart = "on-failure";
    };
  };
}
