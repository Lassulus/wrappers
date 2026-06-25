{
  pkgs,
  self,
}:

let
  voxtypeWrapped =
    (self.wrapperModules.voxtype.apply {
      inherit pkgs;
    }).wrapper;
in
pkgs.runCommand "voxtype-test" { } ''
  # this will fail, if the default config is off
  "${voxtypeWrapped}/bin/voxtype" config
  touch $out
''
