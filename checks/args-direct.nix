{
  pkgs,
  self,
}:

let
  escapedArgsPackage = self.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.hello;
    args = [
      "--greeting"
      "hi"
      "--verbose"
    ];
  };
  unescapedArgsPackage = self.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.hello;
    unquotedArgs = [
      "--greeting"
      "hi"
      "--verbose"
    ];
  };

in
pkgs.runCommand "args-direct-test" { } ''
  echo "Testing direct args list..."

  wrapperScript="${escapedArgsPackage}/bin/hello"
  echo "Check escaped arguments"
  if [ ! -f "$wrapperScript" ]; then
    echo "FAIL: Wrapper script not found"
    exit 1
  fi

  if ! grep -q -- '"--greeting"' "$wrapperScript"; then
    echo "FAIL: escaped --greeting not found"
    cat "$wrapperScript"
    exit 1
  fi

  if ! grep -q '"hi"' "$wrapperScript"; then
    echo "FAIL: escaped 'hi' not found"
    cat "$wrapperScript"
    exit 1
  fi

  if ! grep -q -- '"--verbose"' "$wrapperScript"; then
    echo "FAIL: escaped --verbose not found"
    cat "$wrapperScript"
    exit 1
  fi
  echo "SUCCESS: escaped arguments passed"

  wrapperScript="${unescapedArgsPackage}/bin/hello"
  echo "Check unescaped arguments"
  # check that arguments are present
  if ! grep -q -- "--greeting" "$wrapperScript"; then
    echo "FAIL: --greeting not found"
    cat "$wrapperScript"
    exit 1
  fi

  if ! grep -q "hi" "$wrapperScript"; then
    echo "FAIL: 'hi' not found"
    cat "$wrapperScript"
    exit 1
  fi

  # check hat arguments are not escaped
  if ! grep -q -- "--verbose" "$wrapperScript"; then
    echo "FAIL: --verbose not found"
    cat "$wrapperScript"
    exit 1
  fi

  if grep -q -- '"--greeting"' "$wrapperScript"; then
    echo "FAIL: escaped --greeting found (should be unescaped)"
    cat "$wrapperScript"
    exit 1
  fi

  if grep -q '"hi"' "$wrapperScript"; then
    echo "FAIL: escaped 'hi' found (should be unescaped)"
    cat "$wrapperScript"
    exit 1
  fi


  if grep -q -- '"--verbose"' "$wrapperScript"; then
    echo "FAIL: escaped --verbose found (should be unescaped)"
    cat "$wrapperScript"
    exit 1
  fi
  echo "SUCCESS: escaped arguments passed"

  echo ""
  echo "SUCCESS: Direct args test passed"
  touch $out
''
