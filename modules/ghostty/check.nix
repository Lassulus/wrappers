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

  ghosttyFileWrapped =
    (self.wrapperModules.ghostty.apply {
      inherit pkgs;
      configFile.content = ''
        background=123456
      '';
    }).wrapper;

  ghosttyBadConfigWrapped =
    (self.wrapperModules.ghostty.apply {
      inherit pkgs;
      configFile.content = ''
        abadconfigkey=1
      '';
    }).wrapper;

in
pkgs.runCommand "ghostty" { } ''
  "${ghosttyWrapped}/bin/ghostty" +validate-config
  "${ghosttyWrapped}/bin/ghostty" +version | grep -q "${ghosttyWrapped.version}"

  "${ghosttyFileWrapped}/bin/ghostty" +validate-config

  ! "${ghosttyBadConfigWrapped}/bin/ghostty" +validate-config || exit 1

  touch $out
''
