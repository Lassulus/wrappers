{
  pkgs,
  self,
}:

let
  niriWrapped =
    (self.wrapperModules.niri.apply {
      inherit pkgs;

      "config.kdl".content = "";
    }).wrapper;

in
pkgs.runCommand "niri-test" { } ''
  "${niriWrapped}/bin/niri" --version | grep -q "${niriWrapped.version}"
  touch $out
''
