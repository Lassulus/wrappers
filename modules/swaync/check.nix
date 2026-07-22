{ self, pkgs }:
let
  swayncWrapped =
    (self.wrapperModules.swaync.apply {
      inherit pkgs;
      configOptions = {
        keyboard-shortcuts = false;
      };
    }).wrapper;
in
pkgs.runCommand "test-swaync" { nativeBuildInputs = [ swayncWrapped ]; } ''
  swaync -v | grep "${swayncWrapped.version}"
  touch $out
''
