{
  pkgs,
  self,
}:

let
  # Test with a nixpkgs maintainer (lassulus)
  nixpkgsMaintainer = pkgs.lib.maintainers.lassulus;

  helloModule = self.lib.wrapModule (
    { config, ... }:
    {
      config.package = config.pkgs.hello;
      config.meta.maintainers = [ nixpkgsMaintainer ];
    }
  );

  moduleConfig = helloModule.apply { inherit pkgs; };

in
pkgs.runCommand "meta-maintainers-test" { } ''
  echo "Testing meta.maintainers field with nixpkgs maintainer..."

  # Check that meta.maintainers is set correctly
  maintainers='${builtins.toJSON moduleConfig.meta.maintainers}'
  echo "Maintainers: $maintainers"

  # Verify the maintainer has all required fields
  if ! echo "$maintainers" | grep -q "Lassulus"; then
    echo "FAIL: name 'Lassulus' not found in maintainers"
    exit 1
  fi

  if ! echo "$maintainers" | grep -q "lassulus@gmail.com"; then
    echo "FAIL: email 'lassulus@gmail.com' not found in maintainers"
    exit 1
  fi

  if ! echo "$maintainers" | grep -q '"github":"Lassulus"'; then
    echo "FAIL: github 'Lassulus' not found in maintainers"
    exit 1
  fi

  if ! echo "$maintainers" | grep -q '"githubId":621759'; then
    echo "FAIL: githubId '621759' not found in maintainers"
    exit 1
  fi

  if ! echo "$maintainers" | grep -q '@lassulus:lassul.us'; then
    echo "FAIL: matrix '@lassulus:lassul.us' not found in maintainers"
    exit 1
  fi

  echo "SUCCESS: meta.maintainers test passed with nixpkgs maintainer"
  touch $out
''
