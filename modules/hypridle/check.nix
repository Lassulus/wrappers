{
  pkgs,
  self,
}:

let
  hypridleWrapped =
    (self.wrapperModules.hypridle.apply {
      inherit pkgs;

      # example from https://wiki.hypr.land/Hypr-Ecosystem/hypridle/
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          # monitor backlight dimming (2.5min)
          {
            timeout = 150;
            on-timeout = "brightnessctl -s set 10";
            on-resume = "brightnessctl -r";
          }

          # keyboard backlight off (2.5min)
          {
            timeout = 150;
            on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
            on-resume = "brightnessctl -rd rgb:kbd_backlight";
          }

          # lock screen (5min)
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }

          # screen off (5.5min)
          {
            timeout = 330;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
          }

          # suspend (30min)
          {
            timeout = 1800;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    }).wrapper;

in
pkgs.runCommand "hypridle-test" { } ''
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  "${hypridleWrapped}/bin/hypridle" --version | grep -q "${hypridleWrapped.version}"

  touch $out
''
