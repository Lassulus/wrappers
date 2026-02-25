{
  pkgs,
  self,
}:

let
  kanshiWrapped =
    (self.wrapperModules.kanshi.apply {
      inherit pkgs;

      configFile.content = ''
        profile {
          output eDP-1 enable scale 2
        }
      '';

    }).wrapper;

in
pkgs.runCommand "kanshi-test" { } ''

  "${kanshiWrapped}/bin/kanshi" --help 2>&1 | grep -q "config"

  touch $out
''
