{
  pkgs,
  self,
}:

let
  kanshiConfig = pkgs.writeText "kanshi-test-config" ''
    profile {
      output eDP-1 enable scale 2
    }
  '';

  kanshiWrapped =
    (self.wrapperModules.kanshi.apply {
      inherit pkgs;
      configFile.path = toString kanshiConfig;
    }).wrapper;

in
pkgs.runCommand "kanshi-test" { } ''
  help_output="$(${kanshiWrapped}/bin/kanshi --help 2>&1)"
  [[ "$help_output" == *config* ]]

  test -f "${kanshiConfig}"
  grep -qF 'output eDP-1 enable scale 2' "${kanshiConfig}"

  wrapper_script=$(<"${kanshiWrapped}/bin/kanshi")
  [[ "$wrapper_script" == *"--config"* ]]
  [[ "$wrapper_script" == *"${kanshiConfig}"* ]]

  touch $out
''
