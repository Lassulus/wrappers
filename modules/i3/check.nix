{
  pkgs,
  self,
}:

let
  i3Wrapped =
    (self.wrapperModules.i3.apply {
      inherit pkgs;

      configFile.content = ''
        # Test config
        set $mod Mod4
        bindsym $mod+Return exec alacritty
        bindsym $mod+Shift+q kill
      '';

    }).wrapper;

in
pkgs.runCommand "i3-test" { nativeBuildInputs = [ pkgs.dbus ]; } ''

  export DBUS_SESSION_BUS_ADDRESS="unix:path=$PWD/bus"
  dbus-daemon --session --address="$DBUS_SESSION_BUS_ADDRESS" --nofork --nopidfile --print-address &
  DBUS_PID=$!

  "${i3Wrapped}/bin/i3" --version | grep -q "${i3Wrapped.version}"

  kill $DBUS_PID 2>/dev/null || true

  touch $out
''
