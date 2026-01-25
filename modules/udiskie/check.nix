{
  pkgs,
  self,
}:

let
  udiskieWrapped =
    (self.wrapperModules.udiskie.apply {
      inherit pkgs;
      settings = {
        program_options = {
          automount = true;
          notify = true;
        };
      };
    }).wrapper;
in
pkgs.runCommand "udiskie-test" { } ''
  "${udiskieWrapped}/bin/udiskie" --version | grep -q "udiskie"
  touch $out
''
