{ pkgs, self }:
let
  skimWrapped =
    (self.wrapperModules.skim.apply {
      inherit pkgs;
      settings.version = true;
    }).wrapper;
in
pkgs.runCommand "sk-check" { nativeBuildInputs = [ skimWrapped ]; } ''
  sk | grep ${skimWrapped.version}
  touch $out
''
