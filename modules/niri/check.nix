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

  niriWrappedBadConfig =
    (self.wrapperModules.niri.apply {
      inherit pkgs;

      "config.kdl".content = "
        invalid_kdl_config
      ";
    }).wrapper;

in
pkgs.runCommand "niri-test" { } ''
  "${niriWrapped}/bin/niri" --version | grep -q "${niriWrapped.version}"
  "${niriWrapped}/bin/niri" validate
  ! "${niriWrappedBadConfig}/bin/niri" validate || exit 1
  touch $out
''
