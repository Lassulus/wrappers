{
  lib,
  wlib,
  config,
  options,
  ...
}:
let
  flagValueType = lib.types.oneOf [
    (lib.types.uniq lib.types.bool)
    (lib.types.uniq lib.types.path)
    (lib.types.uniq lib.types.str)
    (lib.types.listOf (
      lib.types.oneOf [
        lib.types.path
        lib.types.str
        (lib.types.listOf (
          lib.types.oneOf [
            lib.types.path
            lib.types.str
          ]
        ))
      ]
    ))
  ];

  flagSubmodule = lib.types.submodule {
    options.value = lib.mkOption {
      type = flagValueType;
      description = "The flag value.";
    };
    options.order = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = ''
        Order priority for this flag in the generated args list.
        Lower numbers come first. Default is 1000.
      '';
    };
  };
in
{
  _file = "lib/modules/flags.nix";

  options.flags = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.coercedTo flagValueType (v: { value = v; }) flagSubmodule);
    default = { };
    apply = lib.mapAttrs (_: v: v.value);
    description = ''
      Flags to pass to the wrapper.
      The key is the flag name, the value is the flag value.
      If the value is true, the flag will be passed without a value.
      If the value is false, the flag will not be passed.
      If the value is a list, the flag will be passed multiple times with each value.
      Can also be set to { value = ...; order = N; } to control ordering in args.
    '';
  };

  options._orderedFlags = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.coercedTo flagValueType (v: { value = v; }) flagSubmodule);
    internal = true;
    default = { };
  };

  options.flagSeparator = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      Separator between flag names and values when generating args from flags.
      null (default) for separate argv entries: "--flag" "value"
      "=" for joined: "--flag=value"
    '';
  };

  config._orderedFlags = lib.mkAliasDefinitions options.flags;

  config.args = lib.mkMerge (
    lib.mapAttrsToList (
      name: flagDef:
      lib.mkOrder flagDef.order (
        wlib.flagToArgs {
          inherit name;
          flag = flagDef.value;
          flagSeparator = config.flagSeparator;
        }
      )
    ) config._orderedFlags
  );
}
