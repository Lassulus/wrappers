{
  pkgs,
  self,
}:

let
  btopWrapped =
    (self.wrapperModules.btop.apply {
      inherit pkgs;

      "btop.conf".content = ''
        color_theme = "TTY"
        update_ms = 2000
      '';

    }).wrapper;

in
pkgs.runCommand "btop-test" { } ''

  "${btopWrapped}/bin/btop" --version | grep -q "btop"

  touch $out
''
