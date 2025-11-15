{
  pkgs,
  self,
}:

let
  weztermWrapped =
    (self.wrapperModules.wezterm.apply {
      inherit pkgs;

      "wezterm.lua".content = # lua
        ''
          local wezterm = require 'wezterm'

          return {
            keys = {
              {
                key = 'F13',
                mods = 'SUPER|CTRL|ALT|SHIFT',
                action = wezterm.action.Nop,
              }
            }
          }
        '';
    }).wrapper;
in
pkgs.runCommand "wezterm-test" { } ''
  res=$("${weztermWrapped}/bin/wezterm" show-keys)

  if ! echo "$res" | grep -q "SHIFT | ALT | CTRL | SUPER   F13"; then
    echo "Wezterm doesn't see custom keybind"
    touch $out
    exit 1
  fi

  touch $out
''
