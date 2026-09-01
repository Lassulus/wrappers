{
  pkgs,
  self,
}:

let
  noctaliaWrapped =
    (self.wrapperModules.noctalia.apply {
      inherit pkgs;
    }).wrapper;

in
pkgs.runCommand "noctalia-test" { } ''
  res=$(${pkgs.lib.getExe noctaliaWrapped} config validate)
  if [[ "$res" == "✓ Config is valid" ]]; then
    touch $out
  fi
''
