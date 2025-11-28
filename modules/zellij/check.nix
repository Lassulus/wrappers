{
  pkgs,
  self,
}:

let
  zellijWrapped =
    (self.wrapperModules.zellij.apply {
      inherit pkgs;
      "config.kdl".content = ''
        layout_dir "/some/path"
      '';
    }).wrapper;
in
pkgs.runCommand "zellij-test" { } ''
  "${zellijWrapped}/bin/zellij" setup --check | grep -q '\[LAYOUT DIR\]: "/some/path"'
  touch $out
''
