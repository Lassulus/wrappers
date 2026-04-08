{
  lib,
  wlib,
  config,
  ...
}:
let
  # A part of an env value list: either a literal string or a reference
  # to another environment variable (produced by `wlib.envRef`). We
  # use a custom type with a runtime check so we don't run into
  # type-merging quirks between `lib.types.str` and submodules.
  envPartType = lib.mkOptionType {
    name = "envValuePart";
    description = "environment variable value part (string or wlib.envRef)";
    check =
      v:
      builtins.isString v
      || (
        builtins.isAttrs v
        && v ? _type
        && v._type == "envRef"
        && v ? name
        && builtins.isString v.name
      );
    merge = lib.options.mergeEqualOption;
  };

  # A single env entry. The submodule is intentionally permissive: any
  # combination of `value`/`values`/`prefix`/`suffix` is allowed, the
  # renderer composes them in a defined order:
  #
  #     prefix ++ (values OR [value] OR [envRef self]) ++ suffix
  #
  # Empty parts are filtered at runtime, so unset/empty env refs drop
  # out without leaving stray separators.
  envEntrySubmodule = lib.types.submodule {
    options = {
      value = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.coercedTo lib.types.path toString lib.types.str
        );
        default = null;
        description = ''
          Literal string value for the variable. Setting a plain
          string via `env.VAR = "..."` coerces to this field. Nix
          paths are accepted and stringified automatically, matching
          the behaviour of the old `attrsOf str` type.
        '';
      };
      values = lib.mkOption {
        type = lib.types.listOf envPartType;
        default = [ ];
        description = ''
          Explicit list of parts to join with `separator`. Parts may
          be literal strings or env references produced by
          `wlib.envRef "NAME"`. Empty parts are skipped at runtime,
          so unset references don't leave dangling separators.

          If both `value` and `values` are set, `value` is spliced
          into the middle of the resulting list (after `prefix` and
          before `values`). This makes composition via `apply`
          predictable: each module contributes more parts to the
          list rather than fighting over a single string.
        '';
      };
      prefix = lib.mkOption {
        type = lib.types.listOf envPartType;
        default = [ ];
        description = ''
          Parts to prepend to the existing value of the variable.
          Equivalent to `makeWrapper`'s `--prefix VAR SEP VAL`. The
          existing value is implicitly referenced; if it is unset or
          empty, it drops out cleanly.
        '';
      };
      suffix = lib.mkOption {
        type = lib.types.listOf envPartType;
        default = [ ];
        description = ''
          Parts to append to the existing value of the variable.
          Equivalent to `makeWrapper`'s `--suffix VAR SEP VAL`.
        '';
      };
      separator = lib.mkOption {
        type = lib.types.str;
        default = ":";
        description = ''
          Separator used when joining list-valued entries. Defaults
          to `:`, which is the conventional separator for PATH-like
          variables.
        '';
      };
      fallback = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Only set the variable when it is not already set in the
          environment. Uses `$\{VAR+set}` semantics: an empty but
          set variable is left alone. Useful for "default" values
          like `EDITOR`, `PAGER`, etc.
        '';
      };
      unset = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Unset the variable instead of assigning it. Takes
          precedence over all other options on this entry.
        '';
      };
    };
  };

  # Type that users set `env` to. Plain strings, paths and `null`
  # coerce into the submodule form so that existing
  # `env.FOO = "bar"` keeps working (paths also accepted and
  # stringified) and `env.FOO = null` is sugar for `{ unset = true; }`.
  envValueType = lib.types.coercedTo (
    lib.types.nullOr (lib.types.either lib.types.str lib.types.path)
  ) (v: if v == null then { unset = true; } else { value = toString v; }) envEntrySubmodule;
in
{
  _file = "lib/modules/env.nix";

  options.env = lib.mkOption {
    type = lib.types.attrsOf envValueType;
    default = { };
    example = lib.literalExpression ''
      {
        # Simple literal.
        FOO = "bar";

        # Prepend to PATH, keeping the user's existing entries.
        PATH.prefix = [ "/opt/bin" ];

        # Build an XDG_DATA_DIRS-like value with an explicit list.
        XDG_DATA_DIRS.values = [
          "/opt/share"
          (wlib.envRef "XDG_DATA_DIRS")
          "/usr/local/share"
        ];

        # Only set EDITOR when the user hasn't already picked one.
        EDITOR = { value = "vim"; fallback = true; };

        # Explicitly unset a variable.
        OLD_VAR = null;
      }
    '';
    description = ''
      Environment variables to set in the wrapper.

      Each entry accepts either a plain string (literal value),
      `null` (unset the variable), or a structured attribute set with
      the following fields:

      - `value`: literal string value.
      - `values`: list of parts joined with `separator`. Parts may
        be plain strings or env references produced by
        `wlib.envRef "NAME"`.
      - `prefix` / `suffix`: parts to splice around the existing
        value of the variable. Empty or unset references drop out
        cleanly, so no dangling separators are left behind.
      - `separator`: join separator (default `:`).
      - `fallback`: if true, only set the variable when it is not
        already present in the caller's environment.
      - `unset`: if true, emit `unset VAR` instead of an assignment.

      The plain-string and `null` forms coerce into this submodule,
      so existing `env.FOO = "bar"` usage keeps working unchanged.
    '';
  };

  # Subset of `env` that resolves to a static literal string with no
  # runtime composition. Used by the systemd integration, which cannot
  # express bash-style prefix/suffix assignments natively. Entries
  # using `prefix`, `suffix`, `values`, `fallback` or `unset` are
  # omitted and must be set via `systemd.environment` directly if they
  # need to reach the service file.
  options.outputs.staticEnv = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    internal = true;
    readOnly = true;
    description = ''
      Subset of `env` that resolves to a plain literal string. Used
      by integrations like systemd that cannot express runtime env
      composition. Complex entries are silently dropped; set them via
      the integration's own environment option if you need them.
    '';
    default = lib.mapAttrs (_: entry: entry.value) (
      lib.filterAttrs (
        _: entry:
        !entry.unset
        && !entry.fallback
        && entry.value != null
        && entry.values == [ ]
        && entry.prefix == [ ]
        && entry.suffix == [ ]
      ) config.env
    );
  };
}
