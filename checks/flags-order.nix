{
  pkgs,
  self,
}:

let
  helloModule = self.lib.wrapModule (
    { config, ... }:
    {
      config.package = config.pkgs.hello;
      config.flags = {
        # default order 1000: before "$@" (which is 1001)
        "--greeting" = "hello";
        # explicit early order: should come first
        "--early" = {
          value = true;
          order = 500;
        };
        # explicit late order: should come after "$@"
        "--late" = {
          value = true;
          order = 1500;
        };
      };
    }
  );

  wrappedPackage = (helloModule.apply { inherit pkgs; }).wrapper;

in
pkgs.runCommand "flags-order-test" { } ''
  echo "Testing flag ordering with priorities..."

  wrapperScript="${wrappedPackage}/bin/hello"
  if [ ! -f "$wrapperScript" ]; then
    echo "FAIL: Wrapper script not found"
    exit 1
  fi

  cat "$wrapperScript"

  # Flatten the script to a single line for position comparison
  flat=$(cat "$wrapperScript" | tr -d '\n' | tr -s ' ')

  # --early (500) should come before --greeting (1000)
  # --greeting (1000) should come before "$@" (1001)
  # "$@" (1001) should come before --late (1500)
  earlyPos=$(echo "$flat" | grep -bo -- '--early' | head -1 | cut -d: -f1)
  greetingPos=$(echo "$flat" | grep -bo -- '--greeting' | head -1 | cut -d: -f1)
  passthruPos=$(echo "$flat" | grep -bo '"\$@"' | head -1 | cut -d: -f1)
  latePos=$(echo "$flat" | grep -bo -- '--late' | head -1 | cut -d: -f1)

  echo "Positions: early=$earlyPos greeting=$greetingPos passthru=$passthruPos late=$latePos"

  if [ "$earlyPos" -ge "$greetingPos" ]; then
    echo "FAIL: --early should come before --greeting"
    exit 1
  fi
  if [ "$greetingPos" -ge "$passthruPos" ]; then
    echo "FAIL: --greeting should come before \"\$@\""
    exit 1
  fi
  if [ "$passthruPos" -ge "$latePos" ]; then
    echo "FAIL: \"\$@\" should come before --late"
    exit 1
  fi

  echo "SUCCESS: Flag ordering test passed"
  touch $out
''
