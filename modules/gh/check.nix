{
  pkgs,
  self,
}:
let
  ghWrapped =
    (self.wrapperModules.gh.apply {
      inherit pkgs;
      settings = {
        version = 1;
        telemetry = "disabled";
      };
    }).wrapper;
in
pkgs.runCommand "gh-test" { nativeBuildInputs = [ ghWrapped ]; } ''
  gh version | grep "${ghWrapped.version}"
  gh config get telemetry | grep disabled
  touch $out
''
