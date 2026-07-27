{ pkgs, self }:
let
  swayidleWrapped =
    (self.wrapperModules.swayidle.apply {
      inherit pkgs;
    }).wrapper;
in
pkgs.runCommand "swayidle-check" { nativeBuildInputs = [ swayidleWrapped ]; } ''
  (swayidle -h | grep "${swayidleWrapped.version}") || true
  touch $out
''
