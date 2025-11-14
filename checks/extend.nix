{
  pkgs,
  self,
}:

let
  lib = pkgs.lib;

  # Create a wrapper module with a custom option
  customModule = self.lib.wrapModule (
    { config, ... }:
    {
      options = {
        customGreeting = lib.mkOption {
          type = lib.types.str;
          default = "hello";
          description = "Custom greeting option";
        };
      };

      config.package = config.pkgs.hello;
      config.flags = {
        "--greeting" = config.customGreeting;
      };
    }
  );

  # Apply with initial settings
  initialConfig = customModule.apply {
    inherit pkgs;
    customGreeting = "initial";
  };

  # Test 1: extend returns a module with config, extendModules, etc.
  extended1 = initialConfig.extend {
    customGreeting = lib.mkForce "extended";
  };

  # Test 2: Add a new option via extend
  extended2 = initialConfig.extend (
    { config, ... }:
    {
      options = {
        verboseMode = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable verbose mode";
        };
      };

      config.flags."--verbose" = lib.mkIf config.verboseMode { };
    }
  );

  # Test 3: Use the new option
  extended3 = extended2.extendModules {
    modules = [
      { verboseMode = true; }
    ];
  };

  # Test 4: Combine custom option changes with new options
  extended4 = initialConfig.extend (
    { config, ... }:
    {
      options = {
        extraFlag = lib.mkOption {
          type = lib.types.str;
          default = "default";
        };
      };

      config.customGreeting = lib.mkForce "combined";
      config.flags."--extra" = config.extraFlag;
    }
  );

  # Test 5: Override the new option
  extended5 = extended4.extendModules {
    modules = [
      { extraFlag = "overridden"; }
    ];
  };

in
pkgs.runCommand "extend-test" { } ''
  echo "Testing extend function..."

  # Test 1: extended1 should be a module, not just config
  extended1Config="${extended1.config.wrapper}/bin/hello"
  if ! grep -q "extended" "$extended1Config"; then
    echo "FAIL: extended1 should have 'extended' greeting"
    cat "$extended1Config"
    exit 1
  fi
  echo "PASS: extend returns module with .config"

  # Test 2: extended1 should preserve pkgs from initial apply
  if [ ! -f "$extended1Config" ]; then
    echo "FAIL: extended1 should have a valid wrapper"
    exit 1
  fi
  echo "PASS: extend preserves pkgs from initial apply"

  # Test 3: Can add new options via extend
  extended2Config="${extended2.config.wrapper}/bin/hello"
  if grep -q -- "--verbose" "$extended2Config"; then
    echo "FAIL: extended2 should not have --verbose when verboseMode is false"
    cat "$extended2Config"
    exit 1
  fi
  echo "PASS: New option added via extend (default value works)"

  # Test 4: Can use the new option
  extended3Config="${extended3.config.wrapper}/bin/hello"
  if ! grep -q -- "--verbose" "$extended3Config"; then
    echo "FAIL: extended3 should have --verbose when verboseMode is true"
    cat "$extended3Config"
    exit 1
  fi

  if ! grep -q "initial" "$extended3Config"; then
    echo "FAIL: extended3 should preserve 'initial' greeting from original apply"
    cat "$extended3Config"
    exit 1
  fi
  echo "PASS: New option can be used and original settings preserved"

  # Test 5: Combine custom option changes with new options
  extended4Config="${extended4.config.wrapper}/bin/hello"
  if ! grep -q "combined" "$extended4Config"; then
    echo "FAIL: extended4 should have 'combined' greeting"
    cat "$extended4Config"
    exit 1
  fi

  if ! grep -q -- "--extra" "$extended4Config"; then
    echo "FAIL: extended4 should have --extra flag"
    cat "$extended4Config"
    exit 1
  fi

  if ! grep -q "default" "$extended4Config"; then
    echo "FAIL: extended4 should have 'default' value for extraFlag"
    cat "$extended4Config"
    exit 1
  fi
  echo "PASS: Can combine option changes with new options"

  # Test 6: Override the new option
  extended5Config="${extended5.config.wrapper}/bin/hello"
  if ! grep -q "overridden" "$extended5Config"; then
    echo "FAIL: extended5 should have 'overridden' value for extraFlag"
    cat "$extended5Config"
    exit 1
  fi

  if ! grep -q "combined" "$extended5Config"; then
    echo "FAIL: extended5 should preserve 'combined' greeting"
    cat "$extended5Config"
    exit 1
  fi
  echo "PASS: Can override new options via extendModules"

  echo "SUCCESS: All extend tests passed"
  touch $out
''
