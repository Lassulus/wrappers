{
  pkgs,
  self,
}:

let
  ghosttyWrapped =
    (self.wrapperModules.ghostty.apply {
      inherit pkgs;

      settings = {
        background = "123456";
      };
    }).wrapper;

in
pkgs.runCommand "ghostty" { } ''
  "${ghosttyWrapped}/bin/ghostty" +validate-config
  "${ghosttyWrapped}/bin/ghostty" +version | grep -q "${ghosttyWrapped.version}"
  touch $out
''
