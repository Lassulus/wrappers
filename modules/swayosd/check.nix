{
  pkgs,
  self,
}:

let
  swayosdWrapped =
    (self.wrapperModules.swayosd.apply {
      inherit pkgs;

      settings = {
        server = {
          max_volume = 150;
          min_brightness = 5;
        };
      };
    }).wrapper;

in
pkgs.runCommand "swayosd-test" { } ''
  test -x "${swayosdWrapped}/bin/swayosd-server"

  touch $out
''
