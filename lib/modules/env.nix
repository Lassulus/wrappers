{
  lib,
  wlib,
  config,
  ...
}:
let
  # A part of an `env.<NAME>.value` list: a literal string or a
  # runtime reference produced by `wlib.env.ref`.
  envPart = lib.mkOptionType {
    name = "envPart";
    description = "string or wlib.env.ref";
    check =
      v: builtins.isString v || (builtins.isAttrs v && (v._type or null) == "envRef");
    merge = lib.options.mergeEqualOption;
  };

  valueType = lib.types.either lib.types.str (lib.types.listOf envPart);

  entry = lib.types.submodule {
    options = {
      value = lib.mkOption {
        type = lib.types.nullOr valueType;
        default = null;
        description = ''
          What to set the variable to. Accepts either a single
          string (literal), or a list of parts joined with
          `separator`. List parts can be plain strings or
          `wlib.env.ref "NAME"` runtime references; empty parts
          (e.g. unset refs) are filtered at runtime so no dangling
          separators are left behind.
        '';
      };
      separator = lib.mkOption {
        type = lib.types.str;
        default = ":";
        description = "Separator used when joining a list-valued `value`.";
      };
      ifUnset = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Only apply this entry when the variable is unset (or
          empty) in the caller's environment. Useful for defaults
          like `EDITOR = "vim"`.
        '';
      };
      unset = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Unset the variable (takes precedence over `value`).";
      };
    };
  };

  envValue = lib.types.coercedTo (
    lib.types.nullOr (lib.types.either lib.types.str lib.types.path)
  ) (v: if v == null then { unset = true; } else { value = toString v; }) entry;
in
{
  _file = "lib/modules/env.nix";

  options.env = lib.mkOption {
    type = lib.types.attrsOf envValue;
    default = { };
    example = lib.literalExpression ''
      {
        FOO = "bar";                                        # literal
        BLOAT = null;                                       # unset
        PATH.value = [ "/opt/bin" (wlib.env.ref "PATH") ];  # prepend
        EDITOR = { value = "vim"; ifUnset = true; };        # default
      }
    '';
    description = ''
      Environment variables to set in the wrapper.

      Each entry accepts:
      - a plain string: literal value
      - `null`: unset the variable
      - a submodule with `value`/`separator`/`ifUnset`/`unset`

      To prepend/append to an existing variable, pass `value` as a
      list and include `wlib.env.ref "NAME"` at the point where the
      existing value should appear:

          env.PATH.value = [ "/opt/bin" (wlib.env.ref "PATH") ];
    '';
  };

  # Subset of `env` that resolves to a plain literal string. Used by
  # the systemd integration, which cannot express runtime env
  # composition. Complex entries are silently dropped — set them via
  # `systemd.environment` directly if you need them.
  options.outputs.staticEnv = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    internal = true;
    readOnly = true;
    description = "Plain literal `env` entries, for integrations like systemd.";
    default = lib.mapAttrs (_: e: e.value) (
      lib.filterAttrs (
        _: e:
        !e.unset && !e.ifUnset && e.value != null && !(builtins.isList e.value)
      ) config.env
    );
  };
}
