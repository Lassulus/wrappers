{
  pkgs,
  self,
}:

let
  swaylockWrapped =
    (self.wrapperModules.swaylock.apply {
      inherit pkgs;

      settings = {
        color = "1e1e2e";
        indicator-radius = 100;
        show-failed-attempts = true;
      };
    }).wrapper;

in
pkgs.runCommand "swaylock-test" { } ''
  "${swaylockWrapped}/bin/swaylock" --version | grep -q "swaylock"

  touch $out
''
