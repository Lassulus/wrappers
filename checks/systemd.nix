{
  pkgs,
  self,
}:

let
  lib = pkgs.lib;

  # Test 1: Defaults from wrapper, both outputs from same config
  withDefaults = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        flags."--greeting" = "world";
        env.HELLO_LANG = "en";
        systemd = {
          description = "Hello service";
          serviceConfig.Type = "simple";
          wantedBy = [ "default.target" ];
        };
      };
    }
  );

  # Test 2: Override ExecStart
  withOverride = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        env.FOO = "bar";
        systemd.serviceConfig = {
          ExecStart = "/custom/bin/thing";
          Type = "oneshot";
        };
      };
    }
  );

  # Test 3: Service name from binName
  customBinName = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        binName = "my-hello";
        systemd.serviceConfig.Type = "simple";
      };
    }
  );

  # Test 4: Deep merging via apply
  baseModule = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        systemd = {
          description = "Hello service";
          serviceConfig.Type = "simple";
          wantedBy = [ "default.target" ];
        };
      };
    }
  );

  extended = baseModule.apply {
    systemd.serviceConfig.Restart = "always";
    systemd.environment.EXTRA = "value";
  };

  # Test 5: Unit ordering
  withDeps = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        systemd = {
          description = "Hello with deps";
          after = [ "network.target" ];
          wants = [ "network.target" ];
          serviceConfig.Type = "simple";
        };
      };
    }
  );

  # Test 6: exePath, extraPackages, preHook, postHook
  withHooks = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        extraPackages = [ pkgs.jq ];
        preHook = "echo pre";
        postHook = "echo post";
        systemd.serviceConfig.Type = "simple";
      };
    }
  );

  # Test 7: startAt generates a timer
  withTimer = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        systemd = {
          serviceConfig.Type = "oneshot";
          startAt = "hourly";
        };
      };
    }
  );

  # Test 8: Args with spaces are properly quoted for systemd
  withSpacedArgs = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        flags."--greeting" = "hello world";
        systemd.serviceConfig.Type = "simple";
      };
    }
  );

  # Test 9: Args with quotes and backslashes
  withSpecialArgs = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        flags."--greeting" = ''say "hi"'';
        systemd.serviceConfig.Type = "simple";
      };
    }
  );

  # Test 10: Env vars with spaces
  withSpecialEnv = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        env.MY_VAR = "hello world";
        env.SIMPLE = "plain";
        systemd.serviceConfig.Type = "simple";
      };
    }
  );

  # Test 11: Multiple extraPackages in PATH
  withMultiPath = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        extraPackages = [
          pkgs.jq
          pkgs.coreutils
        ];
        systemd.serviceConfig.Type = "simple";
      };
    }
  );

  # Test 12: Minimal config (only required fields)
  minimalConfig = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
      };
    }
  );

  # Test 13: wrapper output still works when systemd module is imported
  withWrapper = self.lib.wrapModule (
    {
      config,
      lib,
      wlib,
      ...
    }:
    {
      imports = [ wlib.modules.systemd ];
      config = {
        pkgs = pkgs;
        package = pkgs.hello;
        flags."--greeting" = "world";
        systemd.serviceConfig.Type = "simple";
      };
    }
  );

  readUserService = drv: name: builtins.readFile "${drv}/systemd/user/${name}.service";
  readSystemService = drv: name: builtins.readFile "${drv}/systemd/system/${name}.service";
  readUserTimer = drv: name: builtins.readFile "${drv}/systemd/user/${name}.timer";
  readSystemTimer = drv: name: builtins.readFile "${drv}/systemd/system/${name}.timer";
in
pkgs.runCommand "systemd-test" { } ''
  echo "Testing systemd module..."

  # Test 1a: User service output
  echo "Test 1a: User service defaults from wrapper"
  user='${readUserService withDefaults.outputs.systemd-user "hello"}'
  echo "$user" | grep -q 'Description=Hello service' || { echo "FAIL: missing description"; exit 1; }
  echo "$user" | grep -q 'ExecStart=.*/bin/hello' || { echo "FAIL: ExecStart should default to exePath"; echo "$user"; exit 1; }
  echo "$user" | grep -q '\-\-greeting' || { echo "FAIL: ExecStart should include args"; echo "$user"; exit 1; }
  echo "$user" | grep -qF '"HELLO_LANG=en"' || { echo "FAIL: Environment should include env"; echo "$user"; exit 1; }
  echo "$user" | grep -q 'WantedBy=default.target' || { echo "FAIL: missing WantedBy"; exit 1; }
  echo "PASS: user service defaults"

  # Test 1b: System service output from same config
  echo "Test 1b: System service output from same config"
  system='${readSystemService withDefaults.outputs.systemd-system "hello"}'
  echo "$system" | grep -q 'Description=Hello service' || { echo "FAIL: missing description"; exit 1; }
  echo "$system" | grep -q 'ExecStart=.*/bin/hello' || { echo "FAIL: ExecStart should default to exePath"; echo "$system"; exit 1; }
  echo "$system" | grep -qF '"HELLO_LANG=en"' || { echo "FAIL: Environment should include env"; echo "$system"; exit 1; }
  echo "PASS: system service output from same config"

  # Test 2: Override ExecStart
  echo "Test 2: Override ExecStart"
  override='${readUserService withOverride.outputs.systemd-user "hello"}'
  echo "$override" | grep -q 'ExecStart=/custom/bin/thing' || { echo "FAIL: ExecStart override not applied"; echo "$override"; exit 1; }
  echo "$override" | grep -q 'Type=oneshot' || { echo "FAIL: Type override not applied"; exit 1; }
  echo "PASS: override ExecStart"

  # Test 3: Service name from binName
  echo "Test 3: Service name from binName"
  test -f "${customBinName.outputs.systemd-user}/systemd/user/my-hello.service" || {
    echo "FAIL: user service file should be named my-hello.service"
    ls -la "${customBinName.outputs.systemd-user}/systemd/user/"
    exit 1
  }
  test -f "${customBinName.outputs.systemd-system}/systemd/system/my-hello.service" || {
    echo "FAIL: system service file should be named my-hello.service"
    ls -la "${customBinName.outputs.systemd-system}/systemd/system/"
    exit 1
  }
  echo "PASS: service name from binName"

  # Test 4: Deep merging via apply
  echo "Test 4: Deep merging via apply"
  extended='${readUserService extended.outputs.systemd-user "hello"}'
  echo "$extended" | grep -q 'Description=Hello service' || { echo "FAIL: description lost after apply"; exit 1; }
  echo "$extended" | grep -q 'Type=simple' || { echo "FAIL: Type lost after apply"; exit 1; }
  echo "$extended" | grep -q 'Restart=always' || { echo "FAIL: Restart not merged"; exit 1; }
  echo "$extended" | grep -qF '"EXTRA=value"' || { echo "FAIL: environment not merged"; exit 1; }
  echo "$extended" | grep -q 'WantedBy=default.target' || { echo "FAIL: WantedBy lost after apply"; exit 1; }
  echo "PASS: deep merging via apply"

  # Test 5: Unit ordering
  echo "Test 5: Unit ordering"
  withDeps='${readUserService withDeps.outputs.systemd-user "hello"}'
  echo "$withDeps" | grep -q 'After=network.target' || { echo "FAIL: missing After"; exit 1; }
  echo "$withDeps" | grep -q 'Wants=network.target' || { echo "FAIL: missing Wants"; exit 1; }
  echo "PASS: unit ordering"

  # Test 6: exePath, extraPackages, preHook, postHook
  echo "Test 6: exePath, extraPackages, preHook, postHook"
  hooks='${readUserService withHooks.outputs.systemd-user "hello"}'
  echo "$hooks" | grep -q 'ExecStart=${pkgs.hello}/bin/hello' || { echo "FAIL: ExecStart should use exePath"; echo "$hooks"; exit 1; }
  echo "$hooks" | grep -q '${pkgs.jq}' || { echo "FAIL: extraPackages (jq) not in PATH"; echo "$hooks"; exit 1; }
  echo "$hooks" | grep -q 'ExecStartPre=.*hello-pre-start' || { echo "FAIL: preHook not mapped to ExecStartPre"; echo "$hooks"; exit 1; }
  echo "$hooks" | grep -q 'ExecStopPost=.*hello-post-stop' || { echo "FAIL: postHook not mapped to ExecStopPost"; echo "$hooks"; exit 1; }
  echo "PASS: exePath, extraPackages, preHook, postHook"

  # Test 7: startAt generates a timer
  echo "Test 7: startAt generates a timer"
  timerSvc='${readUserService withTimer.outputs.systemd-user "hello"}'
  echo "$timerSvc" | grep -q 'ExecStart=.*/bin/hello' || { echo "FAIL: service missing ExecStart"; echo "$timerSvc"; exit 1; }
  timer='${readUserTimer withTimer.outputs.systemd-user "hello"}'
  echo "$timer" | grep -q 'OnCalendar=hourly' || { echo "FAIL: timer missing OnCalendar"; echo "$timer"; exit 1; }
  echo "$timer" | grep -q 'WantedBy=timers.target' || { echo "FAIL: timer missing WantedBy"; echo "$timer"; exit 1; }
  systemTimer='${readSystemTimer withTimer.outputs.systemd-system "hello"}'
  echo "$systemTimer" | grep -q 'OnCalendar=hourly' || { echo "FAIL: system timer missing OnCalendar"; echo "$systemTimer"; exit 1; }
  echo "PASS: startAt generates a timer"

  # Test 8: Args with spaces are properly quoted
  echo "Test 8: Args with spaces are quoted for systemd"
  spaced='${readUserService withSpacedArgs.outputs.systemd-user "hello"}'
  echo "$spaced" | grep -qF '"hello world"' || { echo "FAIL: spaced arg not quoted"; echo "$spaced"; exit 1; }
  echo "PASS: args with spaces"

  # Test 9: Args with quotes and backslashes
  echo "Test 9: Args with quotes and backslashes"
  special='${readUserService withSpecialArgs.outputs.systemd-user "hello"}'
  echo "$special" | grep -qF '"say \"hi\""' || { echo "FAIL: special chars not escaped"; echo "$special"; exit 1; }
  echo "PASS: args with special chars"

  # Test 10: Env vars with spaces
  echo "Test 10: Env vars with spaces"
  specialEnv='${readUserService withSpecialEnv.outputs.systemd-user "hello"}'
  echo "$specialEnv" | grep -qF 'MY_VAR=hello world' || { echo "FAIL: env with spaces"; echo "$specialEnv"; exit 1; }
  echo "$specialEnv" | grep -qF 'SIMPLE=plain' || { echo "FAIL: simple env missing"; echo "$specialEnv"; exit 1; }
  echo "PASS: env vars with spaces"

  # Test 11: Multiple extraPackages in PATH
  echo "Test 11: Multiple extraPackages in PATH"
  multiPath='${readUserService withMultiPath.outputs.systemd-user "hello"}'
  echo "$multiPath" | grep -q '${pkgs.jq}' || { echo "FAIL: jq not in PATH"; echo "$multiPath"; exit 1; }
  echo "$multiPath" | grep -q '${pkgs.coreutils}' || { echo "FAIL: coreutils not in PATH"; echo "$multiPath"; exit 1; }
  echo "PASS: multiple extraPackages"

  # Test 12: Minimal config produces a valid unit
  echo "Test 12: Minimal config"
  minimal='${readUserService minimalConfig.outputs.systemd-user "hello"}'
  echo "$minimal" | grep -q 'ExecStart=.*/bin/hello' || { echo "FAIL: minimal missing ExecStart"; echo "$minimal"; exit 1; }
  echo "$minimal" | grep -q '\[Service\]' || { echo "FAIL: minimal missing [Service] section"; echo "$minimal"; exit 1; }
  echo "PASS: minimal config"

  # Test 13: wrapper output still works with systemd module
  echo "Test 13: wrapper still works with systemd module"
  ${withWrapper.wrapper}/bin/hello | grep -q 'world' || { echo "FAIL: wrapper broken"; exit 1; }
  echo "PASS: wrapper still works"

  echo "SUCCESS: All systemd tests passed"
  touch $out
''
