{
  pkgs,
  self,
}:

# Prefix/suffix composition for env variables.
#
# Goals:
# 1. A `prefix`/`suffix` entry splices around the existing value of
#    the variable and leaves no dangling separator when that variable
#    is unset or empty.
# 2. Multiple modules contributing to the same variable via `apply`
#    compose via list concatenation, not via string overwriting.
#
# We use a custom variable name (WRAPPER_TEST_VAR) instead of PATH so
# that unsetting it inside a subshell doesn't break the shell itself.
let
  wlib = self.lib;

  showVar = pkgs.writeShellScriptBin "show-var" ''
    printf 'WRAPPER_TEST_VAR=%s\n' "''${WRAPPER_TEST_VAR-<unset>}"
  '';

  base = wlib.wrapModule (
    { config, ... }:
    {
      config.package = showVar;
      config.env.WRAPPER_TEST_VAR.prefix = [ "/base-pre" ];
      config.env.WRAPPER_TEST_VAR.suffix = [ "/base-post" ];
    }
  );

  extended = (base.apply { pkgs = pkgs; }).apply {
    env.WRAPPER_TEST_VAR.prefix = [ "/extra-pre" ];
    env.WRAPPER_TEST_VAR.suffix = [ "/extra-post" ];
  };

  wrapped = extended.wrapper;
in
pkgs.runCommand "env-prefix-suffix-test" { } ''
  set -eu
  script="${wrapped}/bin/show-var"
  if [ ! -f "$script" ]; then
    echo "FAIL: wrapper script not found"
    exit 1
  fi

  # Case 1: WRAPPER_TEST_VAR unset — prefix and suffix join with no
  # dangling separators, no stray reference to the empty existing
  # value.
  unset WRAPPER_TEST_VAR
  result_unset=$("$script" | grep '^WRAPPER_TEST_VAR=' | cut -d= -f2-)
  case "$result_unset" in
    *:*:*)
      # good, at least three parts (two prefixes + two suffixes all
      # joined together — order is list-concatenation order)
      ;;
    *)
      echo "FAIL: unset case collapsed too aggressively: '$result_unset'"
      cat "$script"
      exit 1
      ;;
  esac
  case "$result_unset" in
    *::*)
      echo "FAIL: unset case has double colon (stray separator): '$result_unset'"
      cat "$script"
      exit 1
      ;;
    :*|*:)
      echo "FAIL: unset case has leading/trailing colon: '$result_unset'"
      exit 1
      ;;
    *)
      echo "PASS: unset case has no dangling separators: $result_unset"
      ;;
  esac
  case "$result_unset" in
    */base-pre*) ;;
    *)
      echo "FAIL: base prefix missing: '$result_unset'"
      exit 1
      ;;
  esac
  case "$result_unset" in
    */extra-pre*) ;;
    *)
      echo "FAIL: extra prefix missing (apply list merge?): '$result_unset'"
      exit 1
      ;;
  esac
  case "$result_unset" in
    */base-post*) ;;
    *)
      echo "FAIL: base suffix missing: '$result_unset'"
      exit 1
      ;;
  esac
  case "$result_unset" in
    */extra-post*) ;;
    *)
      echo "FAIL: extra suffix missing (apply list merge?): '$result_unset'"
      exit 1
      ;;
  esac

  # Case 2: WRAPPER_TEST_VAR set — prefixes appear before, suffixes
  # after, and the existing value survives in the middle.
  export WRAPPER_TEST_VAR=/user-value
  result_set=$("$script" | grep '^WRAPPER_TEST_VAR=' | cut -d= -f2-)
  case "$result_set" in
    */user-value*)
      echo "PASS: existing value preserved: $result_set"
      ;;
    *)
      echo "FAIL: existing value lost: '$result_set'"
      exit 1
      ;;
  esac
  # Prefixes must appear before the existing middle value.
  prefix_part="''${result_set%%/user-value*}"
  case "$prefix_part" in
    */base-pre*) ;;
    *)
      echo "FAIL: base prefix not before existing value: '$result_set'"
      exit 1
      ;;
  esac
  # Suffixes must appear after.
  suffix_part="''${result_set##*/user-value}"
  case "$suffix_part" in
    */base-post*) ;;
    *)
      echo "FAIL: base suffix not after existing value: '$result_set'"
      exit 1
      ;;
  esac

  # Case 3: WRAPPER_TEST_VAR set to the empty string. Empty is filtered
  # the same as unset so the middle drops out cleanly.
  export WRAPPER_TEST_VAR=""
  result_empty=$("$script" | grep '^WRAPPER_TEST_VAR=' | cut -d= -f2-)
  case "$result_empty" in
    *::*)
      echo "FAIL: empty existing value left a double colon: '$result_empty'"
      exit 1
      ;;
    *)
      echo "PASS: empty existing value collapsed cleanly: $result_empty"
      ;;
  esac

  echo "SUCCESS: env prefix/suffix composition works"
  touch $out
''
