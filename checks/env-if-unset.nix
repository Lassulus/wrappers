{
  pkgs,
  self,
}:

# `ifUnset` (only set if caller hasn't) and explicit unset.
let
  wlib = self.lib;

  showEnv = pkgs.writeShellScriptBin "show-env" ''
    printf 'EDITOR=%s\n' "''${EDITOR-<unset>}"
    printf 'BLOAT=%s\n' "''${BLOAT-<unset>}"
  '';

  wrapped =
    (wlib.wrapModule (
      { config, ... }:
      {
        config.package = showEnv;
        config.env.EDITOR = {
          value = "vim";
          ifUnset = true;
        };
        # `null` sugar for unset.
        config.env.BLOAT = null;
      }
    ).apply { pkgs = pkgs; }).wrapper;
in
pkgs.runCommand "env-if-unset-test" { } ''
  set -eu
  script="${wrapped}/bin/show-env"

  # ifUnset applied when EDITOR is unset.
  r=$(unset EDITOR && "$script" | grep '^EDITOR=' | cut -d= -f2-)
  [ "$r" = "vim" ] || { echo "FAIL: ifUnset unset: '$r'"; cat "$script"; exit 1; }
  echo "PASS: ifUnset applies when unset"

  # ifUnset yields to an existing value.
  r=$(EDITOR=nano "$script" | grep '^EDITOR=' | cut -d= -f2-)
  [ "$r" = "nano" ] || { echo "FAIL: ifUnset overrode existing: '$r'"; exit 1; }
  echo "PASS: ifUnset preserves existing"

  # Explicit unset beats caller env.
  r=$(BLOAT=garbage "$script" | grep '^BLOAT=' | cut -d= -f2-)
  [ "$r" = "<unset>" ] || { echo "FAIL: unset: '$r'"; cat "$script"; exit 1; }
  echo "PASS: unset overrides caller env"

  touch $out
''
