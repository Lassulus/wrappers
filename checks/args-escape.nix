{
  pkgs,
  self,
}:
let
  wrappedPackageEscaped = self.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.hello;
    args = [
      ''--verbose''
    ];
  };
  wrappedPackageUnescaped = self.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.hello;
    args = [
      ''--verbose''
    ];
    escapeArgs = false;
  };
in
pkgs.runCommand "args-escape-test" { } ''
  echo "Testing escape option for wrapPackage"

  # Test 1: arguments are escaped by default
  wrapperScript="${wrappedPackageEscaped}/bin/hello"
  if [ ! -f "$wrapperScript" ]; then
    echo "FAIL: Wrapper script not found"
    exit 1
  fi

  if ! grep -q -- '"--verbose"' "$wrapperScript"; then
    echo "FAIL: arguments are not escaped by default"
    cat "$wrapperScript"
    exit 1
  fi


  # Test 2: arguments should not be escaped when option is set
  wrapperScript="${wrappedPackageUnescaped}/bin/hello"
  if [ ! -f "$wrapperScript" ]; then
    echo "FAIL: Wrapper script not found"
    exit 1
  fi

  if grep -q -- '"--verbose"' "$wrapperScript"; then
    echo "FAIL: arguments were escaped"
    cat "$wrapperScript"
    exit 1
  fi

  echo "SUCCESS: all args-escape tests passed"
  touch $out
''
