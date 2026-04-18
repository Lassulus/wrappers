{
  pkgs,
  self,
}:
let
  batWrapped =
    (self.wrapperModules.bat.apply {
      inherit pkgs;

      "bat-config".content = ''
        # Test config
        --italic-text=never
        --theme="Catppuccin Mocha"
      '';
    }).wrapper;
in
pkgs.runCommand "bat-test" { } ''
  ${batWrapped}/bin/bat -p </dev/null
  touch $out
''
