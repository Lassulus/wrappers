{
  lib,
  wlib,
  config,
  ...
}:
{
  _file = "lib/modules/wrapper.nix";
  imports = [ wlib.modules.package ];
  options = {
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        Additional packages to add to the wrapper's runtime dependencies.
        This is useful if the wrapped program needs additional libraries or tools to function correctly.
        These packages will be added to the wrapper's runtime dependencies, ensuring they are available when the wrapped program is executed.
      '';
    };
    flags = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified; # TODO add list handling
      default = { };
      description = ''
        Flags to pass to the wrapper.
        The key is the flag name, the value is the flag value.
        If the value is true, the flag will be passed without a value.
        If the value is false or null, the flag will not be passed.
        If the value is a list, the flag will be passed multiple times with each value.
      '';
    };
    flagSeparator = lib.mkOption {
      type = lib.types.str;
      default = " ";
      description = ''
        Separator between flag names and values when generating args from flags.
        " " for "--flag value" or "=" for "--flag=value"
      '';
    };
    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = wlib.generateArgsFromFlags config.flags config.flagSeparator;
      description = ''
        Command-line arguments to pass to the wrapper (like argv in execve).
        This is a list of strings representing individual arguments.
        If not specified, will be automatically generated from flags.
      '';
    };
    env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Environment variables to set in the wrapper.
      '';
    };
    filesToPatch = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "share/applications/*.desktop" ];
      description = ''
        List of file paths (glob patterns) relative to package root to patch for self-references.
        Desktop files are patched by default to update Exec= and Icon= paths.
      '';
    };
    filesToExclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of file paths (glob patterns) relative to package root to exclude from the wrapped package.
        This allows filtering out unwanted binaries or files.
        Example: [ "bin/unwanted-tool" "share/applications/*.desktop" ]
      '';
    };
    exePath = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the executable within the package to be wrapped.
        If not specified, the main executable of the package will be used.
      '';
      default = lib.getExe config.package;
      defaultText = "lib.getExe config.package";
    };
    binName = lib.mkOption {
      type = lib.types.str;
      description = ''
        Name of the binary in the resulting wrapper package.
        If not specified, the base name of exePath will be used.
      '';
      default = builtins.baseNameOf config.exePath;
      defaultText = "builtins.baseNameOf config.exePath";
    };
    wrapper = lib.mkOption {
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
        passthru = {
          configuration = config;
        }
        // config.passthru;
      };
    };
  };
}
