{
  pkgs,
  self,
}:
let
  lib = pkgs.lib;

  # Test wrapper module using environment variable path
  testModule = self.lib.wrapModule (
    { config, wlib, ... }:
    {
      options = {
        "config.txt" = lib.mkOption {
          type = wlib.types.file config.pkgs;
          default.content = "default content";
        };
      };
      config.package = pkgs.writeShellScriptBin "test-app" ''
        # This app reads a config file path from its first argument
        config_path="$1"
        if [ -f "$config_path" ]; then
          echo "Config file found at: $config_path"
          echo "Contents:"
          cat "$config_path"
          exit 0
        else
          echo "Config file not found at: $config_path" >&2
          exit 1
        fi
      '';
      config.args = [ (toString config."config.txt".path) ];
    }
  );

  # Test 1: Using environment variable in path
  wrappedWithEnvVar =
    (testModule.apply {
      pkgs = pkgs;
      "config.txt".path = "$HOME/test-config.txt";
    }).wrapper;

  # Test 2: Using environment variable with fallback
  wrappedWithEnvVarFallback =
    (testModule.apply {
      pkgs = pkgs;
      "config.txt".path = "\${TEST_CONFIG_DIR:-$HOME}/test-config.txt";
    }).wrapper;

  # Test 3: Using absolute path outside store
  wrappedWithAbsolutePath =
    (testModule.apply {
      pkgs = pkgs;
      "config.txt".path = "/tmp/test-config.txt";
    }).wrapper;

  # Test 4: Default behavior (content written to store)
  wrappedWithStoreContent =
    (testModule.apply {
      pkgs = pkgs;
      "config.txt".content = "This is store content";
    }).wrapper;

in
pkgs.runCommand "types-file-env-var-test" { } ''
  set -e
  echo "Testing types.file with environment variables and non-store paths..."

  # Test 1: Environment variable path - $HOME
  echo -e "\n=== Test 1: Environment variable \$HOME ==="
  (
    export HOME=$(mktemp -d)
    echo "test config from HOME" > "$HOME/test-config.txt"

    output=$(${wrappedWithEnvVar}/bin/test-app)
    if echo "$output" | grep -q "Config file found at: $HOME/test-config.txt"; then
      echo "PASS: \$HOME environment variable expanded correctly"
    else
      echo "FAIL: \$HOME not expanded correctly"
      echo "Output: $output"
      exit 1
    fi

    if echo "$output" | grep -q "test config from HOME"; then
      echo "PASS: Config file contents read correctly"
    else
      echo "FAIL: Config file contents not read"
      echo "Output: $output"
      exit 1
    fi
  )

  # Test 2: Environment variable with fallback - using fallback
  echo -e "\n=== Test 2: Environment variable with fallback (using fallback) ==="
  (
    export HOME=$(mktemp -d)
    unset TEST_CONFIG_DIR
    echo "test config from fallback HOME" > "$HOME/test-config.txt"

    output=$(${wrappedWithEnvVarFallback}/bin/test-app)
    if echo "$output" | grep -q "Config file found at: $HOME/test-config.txt"; then
      echo "PASS: Fallback to \$HOME works correctly"
    else
      echo "FAIL: Fallback did not work"
      echo "Output: $output"
      exit 1
    fi
  )

  # Test 2b: Environment variable with fallback - using custom dir
  echo -e "\n=== Test 2b: Environment variable with fallback (using custom dir) ==="
  (
    export TEST_CONFIG_DIR=$(mktemp -d)
    echo "test config from custom dir" > "$TEST_CONFIG_DIR/test-config.txt"

    output=$(${wrappedWithEnvVarFallback}/bin/test-app)
    if echo "$output" | grep -q "Config file found at: $TEST_CONFIG_DIR/test-config.txt"; then
      echo "PASS: Custom TEST_CONFIG_DIR works correctly"
    else
      echo "FAIL: Custom TEST_CONFIG_DIR did not work"
      echo "Output: $output"
      exit 1
    fi

    if echo "$output" | grep -q "test config from custom dir"; then
      echo "PASS: Config file from custom dir read correctly"
    else
      echo "FAIL: Config file from custom dir not read"
      exit 1
    fi
  )

  # Test 3: Absolute path outside store
  echo -e "\n=== Test 3: Absolute path outside store ==="
  echo "test config from /tmp" > /tmp/test-config.txt

  output=$(${wrappedWithAbsolutePath}/bin/test-app)
  if echo "$output" | grep -q "Config file found at: /tmp/test-config.txt"; then
    echo "PASS: Absolute path works correctly"
  else
    echo "FAIL: Absolute path did not work"
    echo "Output: $output"
    exit 1
  fi

  # Test 4: Default behavior (store content)
  echo -e "\n=== Test 4: Default behavior (store content) ==="
  output=$(${wrappedWithStoreContent}/bin/test-app)
  if echo "$output" | grep -q "Config file found at: /nix/store"; then
    echo "PASS: Store path works correctly"
  else
    echo "FAIL: Store path did not work"
    echo "Output: $output"
    exit 1
  fi

  if echo "$output" | grep -q "This is store content"; then
    echo "PASS: Store content read correctly"
  else
    echo "FAIL: Store content not read"
    echo "Output: $output"
    exit 1
  fi

  echo -e "\n=== SUCCESS: All types.file environment variable tests passed ==="
  touch $out
''
