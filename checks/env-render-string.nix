{
  pkgs,
  self,
}:

# Pure rendering tests for `wlib.renderEnvString`. These don't build
# a wrapper, they just assert the generated shell snippet is what we
# expect. Keeps the feedback loop tight when iterating on escaping.
let
  lib = pkgs.lib;
  wlib = self.lib;

  cases = [
    {
      name = "empty";
      input = { };
      expected = "";
    }
    {
      name = "simple-literal";
      input = {
        FOO = "bar";
      };
      expected = ''
        export FOO="bar"
      '';
    }
    {
      name = "null-is-unset";
      input = {
        FOO = null;
      };
      expected = ''
        unset FOO
      '';
    }
    {
      name = "explicit-unset";
      input = {
        FOO = {
          unset = true;
        };
      };
      expected = ''
        unset FOO
      '';
    }
    {
      name = "fallback";
      input = {
        EDITOR = {
          value = "vim";
          fallback = true;
        };
      };
      expected = ''
        if [ -z "''${EDITOR+set}" ]; then
          export EDITOR="vim"
        fi
      '';
    }
    {
      name = "escaped-literal";
      input = {
        # Double quotes and backslashes survive unmangled inside the
        # double-quoted export.
        MSG = ''He said "hi" and went \home'';
      };
      expected = ''
        export MSG="He said \"hi\" and went \\home"
      '';
    }
  ];

  runCase =
    { name, input, expected }:
    let
      actual = wlib.renderEnvString input;
    in
    if actual == expected then
      "PASS: ${name}"
    else
      throw ''
        FAIL: ${name}
        expected:
        ${expected}
        ---
        actual:
        ${actual}
      '';

  results = map runCase cases;

  # Structural assertions that check _prefixes/_contents_ of the
  # generated snippet rather than exact bytes, because the join
  # helper injects a bunch of shell glue that is annoying to match
  # exactly.
  prefixInput = {
    PATH.prefix = [ "/opt/bin" ];
  };
  prefixOut = wlib.renderEnvString prefixInput;
  prefixAsserts =
    if lib.hasInfix "_wrapper_env_join" prefixOut && lib.hasInfix ''"/opt/bin"'' prefixOut then
      "PASS: prefix case includes join helper and literal"
    else
      throw "FAIL: prefix case missing expected content:\n${prefixOut}";

  valuesInput = {
    FOO.values = [
      "A"
      (wlib.envRef "BAR")
      "C"
    ];
  };
  valuesOut = wlib.renderEnvString valuesInput;
  valuesAsserts =
    if
      lib.hasInfix ''"A"'' valuesOut
      && lib.hasInfix ''"''${BAR-}"'' valuesOut
      && lib.hasInfix ''"C"'' valuesOut
    then
      "PASS: values case renders literals and envRef"
    else
      throw "FAIL: values case missing expected content:\n${valuesOut}";

  allResults = results ++ [
    prefixAsserts
    valuesAsserts
  ];
in
pkgs.runCommand "env-render-string-test" { } ''
  cat <<'EOF'
  ${lib.concatStringsSep "\n" allResults}
  EOF
  touch $out
''
