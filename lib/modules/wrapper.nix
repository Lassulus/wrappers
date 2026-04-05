{
  lib,
  wlib,
  config,
  ...
}:
{
  _file = "lib/modules/wrapper.nix";
  imports = [ wlib.modules.command ];
  options.filesToPatch = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "share/applications/*.desktop" ];
    description = ''
      List of file paths (glob patterns) relative to package root to patch for self-references.
      Desktop files are patched by default to update Exec= and Icon= paths.
    '';
  };
  options.filesToExclude = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      List of file paths (glob patterns) relative to package root to exclude from the wrapped package.
      This allows filtering out unwanted binaries or files.
      Example: [ "bin/unwanted-tool" "share/applications/*.desktop" ]
    '';
  };
  options.patchHook = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = ''
      Shell script that runs after patchPhase to modify the wrapper package files.
    '';
  };

  # Inject "$@" (passthrough of user arguments) into args at order 1001,
  # so it comes just after the default flag order (1000).
  # Use mkOrder on args to position it; other flags can use order > 1001
  # to appear after "$@" if needed.
  config.args = lib.mkOrder 1001 [ "$@" ];

  options.outputs.wrapper = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    description = ''
      The wrapped package created by wrapPackage. This wraps the configured package
      with the specified flags, environment variables, runtime dependencies, and other
      options in a portable way.
    '';
    default = wlib.wrapPackage {
      pkgs = config.pkgs;
      package = config.package;
      exePath = config.exePath;
      binName = config.binName;
      runtimeInputs = config.extraPackages;
      flags = config.flags;
      flagSeparator = config.flagSeparator;
      args = config.args;
      env = config.env;
      filesToPatch = config.filesToPatch;
      filesToExclude = config.filesToExclude;
      preHook = config.preHook;
      postHook = config.postHook;
      patchHook = config.patchHook;
      passthru = {
        configuration = config;
      }
      // config.passthru;
    };
  };
  options.wrapper = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    description = ''
      Backward-compatible alias for outputs.wrapper.
    '';
    default = config.outputs.wrapper;
  };
}
