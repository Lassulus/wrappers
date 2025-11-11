{
  pkgs,
  self,
}:
let
  lib = pkgs.lib;
  escape = self.lib.escapeShellArgWithEnv;

in
pkgs.runCommand "escape-shell-arg-with-env-test" { } ''
  echo "Testing escapeShellArgWithEnv..."

  # Test 1: Simple path with environment variable
  result1='${escape "$HOME/config.txt"}'
  expected1='"$HOME/config.txt"'
  if [ "$result1" = "$expected1" ]; then
    echo "PASS: Environment variable preserved"
  else
    echo "FAIL: Environment variable not preserved"
    echo "  Expected: $expected1"
    echo "  Got: $result1"
    exit 1
  fi

  # Test 2: Path with double quote
  result2='${escape "/path/with\"quote"}'
  expected2='"/path/with\"quote"'
  if [ "$result2" = "$expected2" ]; then
    echo "PASS: Double quote escaped"
  else
    echo "FAIL: Double quote not escaped correctly"
    echo "  Expected: $expected2"
    echo "  Got: $result2"
    exit 1
  fi

  # Test 3: Path with backslash
  result3='${escape "/path/with\\backslash"}'
  expected3='"/path/with\\backslash"'
  if [ "$result3" = "$expected3" ]; then
    echo "PASS: Backslash escaped"
  else
    echo "FAIL: Backslash not escaped correctly"
    echo "  Expected: $expected3"
    echo "  Got: $result3"
    exit 1
  fi

  # Test 4: Complex environment variable with fallback
  result4='${escape "\${XDG_CONFIG_HOME:-$HOME/.config}/app.conf"}'
  expected4='"''${XDG_CONFIG_HOME:-$HOME/.config}/app.conf"'
  if [ "$result4" = "$expected4" ]; then
    echo "PASS: Complex environment variable preserved"
  else
    echo "FAIL: Complex environment variable not preserved correctly"
    echo "  Expected: $expected4"
    echo "  Got: $result4"
    exit 1
  fi

  # Test 5: Regular path without special characters
  result5='${escape "/etc/config.txt"}'
  expected5='"/etc/config.txt"'
  if [ "$result5" = "$expected5" ]; then
    echo "PASS: Regular path quoted correctly"
  else
    echo "FAIL: Regular path not quoted correctly"
    echo "  Expected: $expected5"
    echo "  Got: $result5"
    exit 1
  fi

  echo "SUCCESS: All escapeShellArgWithEnv tests passed"
  touch $out
''
