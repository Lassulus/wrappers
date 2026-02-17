{
  pkgs,
  self,
}:

let
  # Create a dummy package with a desktop file that references itself
  dummyPackage =
    (pkgs.runCommand "dummy-app" { } ''
      # empty dir as a package
      mkdir -p $out
    '')
    // {
      meta.mainProgram = "dummy-app";
    };

  # Wrap the package
  wrappedPackage = self.lib.wrapPackage {
    inherit pkgs;
    package = dummyPackage;
    patchHook = ''
      touch $out/test
    '';
  };

in
pkgs.runCommand "patchHook-test"
  {
    wrappedPath = "${wrappedPackage}";
  }
  ''
    echo "Testing patchHook functionality..."
    echo "Wrapped package path: $wrappedPath"

    if [ ! -f "$wrappedPath/test" ]; then
      echo "FAIL: file not created in patched package"
      exit 1
    fi

    echo "SUCCESS: patchHook executed correctly"
    touch $out
  ''
