{
  pkgs,
  self,
}:
let
  lib = pkgs.lib;

  # Test 1: Default behavior (exePath from lib.getExe, binName from basename)
  wrappedDefault = self.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.hello;
  };

  # Test 2: Custom exePath with default binName
  wrappedCustomExe = self.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.coreutils;
    exePath = "${pkgs.coreutils}/bin/ls";
  };

  # Test 3: Custom exePath and custom binName
  wrappedCustomBoth = self.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.coreutils;
    exePath = "${pkgs.coreutils}/bin/ls";
    binName = "my-ls";
  };

  # Test 4: Custom binName with flags
  wrappedWithFlags = self.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.coreutils;
    exePath = "${pkgs.coreutils}/bin/ls";
    binName = "colorful-ls";
    flagSeparator = "=";
    flags = {
      "--color" = "auto";
    };
  };

in
pkgs.runCommand "exe-path-bin-name-test" { } ''
  set -e
  echo "Testing exePath and binName parameters..."

  # Test 1: Default behavior
  echo -e "\n=== Test 1: Default behavior ==="
  if [ -f "${wrappedDefault}/bin/hello" ]; then
    echo "PASS: Default binary name is 'hello'"
  else
    echo "FAIL: Default binary 'hello' not found"
    ls -la ${wrappedDefault}/bin/
    exit 1
  fi

  output=$(${wrappedDefault}/bin/hello)
  if echo "$output" | grep -q "Hello, world!"; then
    echo "PASS: Default binary executes correctly"
  else
    echo "FAIL: Default binary output incorrect"
    echo "Output: $output"
    exit 1
  fi

  # Test 2: Custom exePath with default binName
  echo -e "\n=== Test 2: Custom exePath (ls) ==="
  if [ -f "${wrappedCustomExe}/bin/ls" ]; then
    echo "PASS: Binary name derived from exePath basename is 'ls'"
  else
    echo "FAIL: Binary 'ls' not found"
    ls -la ${wrappedCustomExe}/bin/
    exit 1
  fi

  # Test that it actually executes ls (it should show some output)
  output=$(${wrappedCustomExe}/bin/ls /etc)
  if [ -n "$output" ]; then
    echo "PASS: Custom exePath binary executes correctly"
  else
    echo "FAIL: Custom exePath binary produced no output"
    exit 1
  fi

  # Test 3: Custom exePath and custom binName
  echo -e "\n=== Test 3: Custom exePath and binName ==="
  if [ -f "${wrappedCustomBoth}/bin/my-ls" ]; then
    echo "PASS: Custom binary name 'my-ls' exists"
  else
    echo "FAIL: Custom binary 'my-ls' not found"
    ls -la ${wrappedCustomBoth}/bin/
    exit 1
  fi

  # Note: The original binaries from the package are still present via symlinkJoin
  # This is expected behavior - we add the custom binary but don't remove originals
  if [ -L "${wrappedCustomBoth}/bin/ls" ]; then
    echo "PASS: Original binaries from base package are preserved"
  fi

  output=$(${wrappedCustomBoth}/bin/my-ls /etc)
  if [ -n "$output" ]; then
    echo "PASS: Custom named binary executes correctly"
  else
    echo "FAIL: Custom named binary produced no output"
    exit 1
  fi

  # Test 4: Custom binName with flags
  echo -e "\n=== Test 4: Custom binName with flags ==="
  if [ -f "${wrappedWithFlags}/bin/colorful-ls" ]; then
    echo "PASS: Binary 'colorful-ls' with flags exists"
  else
    echo "FAIL: Binary 'colorful-ls' not found"
    ls -la ${wrappedWithFlags}/bin/
    exit 1
  fi

  # ls --color=auto should work (we can't easily test color output, but we can verify it runs)
  output=$(${wrappedWithFlags}/bin/colorful-ls /etc)
  if [ -n "$output" ]; then
    echo "PASS: Binary with flags executes correctly"
  else
    echo "FAIL: Binary with flags produced no output"
    exit 1
  fi

  echo -e "\n=== SUCCESS: All exePath and binName tests passed ==="
  touch $out
''
