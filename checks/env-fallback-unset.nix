{
  pkgs,
  self,
}:

# Fallback (only-set-if-unset) and explicit unset handling.
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
          fallback = true;
        };
        # `null` is sugar for `unset = true`, exercise both forms.
        config.env.BLOAT = null;
      }
    ).apply { pkgs = pkgs; }).wrapper;
in
pkgs.runCommand "env-fallback-unset-test" { } ''
  set -eu
  script="${wrapped}/bin/show-env"

  # Fallback: EDITOR unset → set to vim.
  editor_unset=$(unset EDITOR && "$script" | grep '^EDITOR=' | cut -d= -f2-)
  if [ "$editor_unset" = "vim" ]; then
    echo "PASS: fallback applied when unset"
  else
    echo "FAIL: fallback unset case: '$editor_unset'"
    cat "$script"
    exit 1
  fi

  # Fallback: EDITOR already set → preserved.
  editor_set=$(EDITOR=nano "$script" | grep '^EDITOR=' | cut -d= -f2-)
  if [ "$editor_set" = "nano" ]; then
    echo "PASS: fallback preserved existing value"
  else
    echo "FAIL: fallback preserved case: '$editor_set'"
    exit 1
  fi

  # Unset: BLOAT should be unset even if caller exports it.
  bloat_result=$(BLOAT=garbage "$script" | grep '^BLOAT=' | cut -d= -f2-)
  if [ "$bloat_result" = "<unset>" ]; then
    echo "PASS: unset overrides caller env"
  else
    echo "FAIL: unset case: '$bloat_result'"
    cat "$script"
    exit 1
  fi

  touch $out
''
