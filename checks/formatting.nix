{
  pkgs,
  self,
}:

pkgs.runCommand "formatting-check" { } ''
  cp -r ${../.}/ src
  # will be copied readonly from the /nix/store
  # nixfmt sadly ignores --fail-on-change and still tries to write to the file
  # ergo, we create our own writable copy
  chmod -R +w src
  ${pkgs.lib.getExe self.formatter.${pkgs.stdenv.hostPlatform.system}} --ci --tree-root ./src ./src
  touch $out
''
