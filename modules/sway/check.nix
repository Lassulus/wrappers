{
  pkgs,
  self,
}:

let
  swayWrapped =
    (self.wrapperModules.sway.apply {
      inherit pkgs;

      configFile.content = ''
        # Test config
        set $mod Mod4
        bindsym $mod+Return exec alacritty
        bindsym $mod+Shift+q kill
      '';

    }).wrapper;

in
pkgs.runCommand "sway-test" { nativeBuildInputs = [ pkgs.dbus ]; } ''

  export DBUS_SESSION_BUS_ADDRESS="unix:path=$PWD/bus"
  dbus-daemon --session --address="$DBUS_SESSION_BUS_ADDRESS" --nofork --nopidfile --print-address &
  DBUS_PID=$!

  "${swayWrapped}/bin/sway" --version | grep -q "${swayWrapped.version}"

  kill $DBUS_PID 2>/dev/null || true

  touch $out
''
