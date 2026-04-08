{
  pkgs,
  self,
}:

# `values` list with explicit envRef placeholders for maximum
# flexibility: put the existing value anywhere in the resulting
# string.
let
  wlib = self.lib;

  showEnv = pkgs.writeShellScriptBin "show-env" ''
    printf 'LD_LIBRARY_PATH=%s\n' "''${LD_LIBRARY_PATH-<unset>}"
  '';

  wrapped =
    (wlib.wrapModule (
      { config, ... }:
      {
        config.package = showEnv;
        config.env.LD_LIBRARY_PATH.values = [
          "/opt/lib"
          (wlib.envRef "LD_LIBRARY_PATH")
          "/other/lib"
        ];
      }
    ).apply { pkgs = pkgs; }).wrapper;
in
pkgs.runCommand "env-values-envref-test" { } ''
  set -eu
  script="${wrapped}/bin/show-env"

  # Unset case: inner envRef drops out, surrounding values joined.
  unset_result=$(unset LD_LIBRARY_PATH && "$script" | grep '^LD_LIBRARY_PATH=' | cut -d= -f2-)
  if [ "$unset_result" = "/opt/lib:/other/lib" ]; then
    echo "PASS: unset case: $unset_result"
  else
    echo "FAIL: unset case: '$unset_result' (expected /opt/lib:/other/lib)"
    cat "$script"
    exit 1
  fi

  # Set case: envRef expands in place, preserving order.
  set_result=$(LD_LIBRARY_PATH=/user/lib "$script" | grep '^LD_LIBRARY_PATH=' | cut -d= -f2-)
  if [ "$set_result" = "/opt/lib:/user/lib:/other/lib" ]; then
    echo "PASS: set case: $set_result"
  else
    echo "FAIL: set case: '$set_result' (expected /opt/lib:/user/lib:/other/lib)"
    exit 1
  fi

  # Empty-string case: an empty existing value is treated like unset
  # so we don't leave stray separators.
  empty_result=$(LD_LIBRARY_PATH="" "$script" | grep '^LD_LIBRARY_PATH=' | cut -d= -f2-)
  if [ "$empty_result" = "/opt/lib:/other/lib" ]; then
    echo "PASS: empty-string case: $empty_result"
  else
    echo "FAIL: empty-string case: '$empty_result' (expected /opt/lib:/other/lib)"
    exit 1
  fi

  touch $out
''
