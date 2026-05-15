{
  pkgs,
  self,
}:

pkgs.runCommand "formatting-check" { } ''
  cd $(mktemp -d)
  #mutable copy to make treefmt opening the files with its default mode happy
  cp ${../.}/* -r ./
  ${pkgs.lib.getExe self.formatter.${pkgs.stdenv.hostPlatform.system}} --ci --tree-root $PWD ./.
  touch $out
''
