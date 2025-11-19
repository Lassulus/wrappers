{
  pkgs,
  self,
}:

let
  wrappedPackage = self.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.hello;
    flags = {
      "--greeting" = "hi";
      "--verbose" = true;
      "--empty" = [ ];
      "--output" = "file.txt";
    };
    flagSeparator = " ";
  };

in
pkgs.runCommand "flags-empty-list-test" { } ''
  echo "Testing flags with empty list..."

  wrapperScript="${wrappedPackage}/bin/hello"
  if [ ! -f "$wrapperScript" ]; then
    echo "FAIL: Wrapper script not found"
    exit 1
  fi

  # Check that flags with non-empty values are present
  if ! grep -q -- "--greeting" "$wrapperScript"; then
    echo "FAIL: --greeting flag not found"
    cat "$wrapperScript"
    exit 1
  fi

  if ! grep -q "hi" "$wrapperScript"; then
    echo "FAIL: greeting value 'hi' not found"
    cat "$wrapperScript"
    exit 1
  fi

  if ! grep -q -- "--verbose" "$wrapperScript"; then
    echo "FAIL: --verbose flag not found"
    cat "$wrapperScript"
    exit 1
  fi

  if ! grep -q -- "--output" "$wrapperScript"; then
    echo "FAIL: --output flag not found"
    cat "$wrapperScript"
    exit 1
  fi

  # Check that empty list flag is NOT present
  if grep -q -- "--empty" "$wrapperScript"; then
    echo "FAIL: --empty flag should be omitted (value was empty list)"
    cat "$wrapperScript"
    exit 1
  fi

  echo "SUCCESS: empty list flags correctly omitted"
  touch $out
''
