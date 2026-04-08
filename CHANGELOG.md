# Changelog

## Unreleased

### Breaking changes

- `wrapPackage`: when passing explicit `args`, `"$@"` is no longer
  appended automatically by the wrapper template. If you pass custom
  `args` and want passthrough, include `"$@"` in your args list.
  The default `args` (generated from `flags`) still includes `"$@"`.

- `flagSeparator` default changed from `" "` to `null`. The old `" "`
  default was misleading: it produced separate argv entries, not a
  space-joined arg. `null` now means separate argv entries. If you
  were explicitly passing `flagSeparator = " "` to get separate args,
  remove it (or change to `null`).

- `env` option type changed from `attrsOf str` to a richer submodule
  (see "Added" below). Plain-string and path values keep coercing to
  the old behaviour, so `env.FOO = "bar"` is unchanged. Passthru
  `wrapPackage` callers now get the structured form on
  `passthru.env`; read `passthru.env.<name>.value` instead of
  `passthru.env.<name>` if you need the literal. The systemd
  integration reads from `config.outputs.staticEnv` instead of
  `config.env` and silently drops entries that can't be expressed as
  a static literal (prefix/suffix, values, fallback, unset).

### Added

- `lib/modules/command.nix`: base module with shared command spec
  (args, env, hooks, exePath) used by both wrapper and systemd outputs.
- `lib/modules/flags.nix`: flags module with per-flag ordering via
  `{ value, order }` submodules. Default order is 1000. Reading
  `config.flags` returns clean values (order is transparent).
- `lib/modules/env.nix`: env module with richer per-variable options
  for safe composition, modelled on `makeWrapper`'s `--prefix` /
  `--suffix` but usable through the NixOS module system.
  - `env.<VAR>.value`: literal string (same as `env.<VAR> = "..."`).
  - `env.<VAR>.prefix` / `.suffix`: parts to splice around the
    existing value of the variable. Empty or unset existing values
    drop out cleanly with no stray separators.
  - `env.<VAR>.values`: explicit list of parts to join, with
    `wlib.envRef "OTHER"` placeholders for runtime env references.
  - `env.<VAR>.separator`: join separator (default `:`).
  - `env.<VAR>.fallback = true`: only set the variable when it is
    not already set in the caller's environment (uses `${VAR+set}`
    semantics).
  - `env.<VAR>.unset = true`: emit `unset VAR` instead of an
    assignment. `env.VAR = null` is sugar for this.
  - List-valued entries (`values`, `prefix`, `suffix`) merge by
    concatenation when composed via `apply`, so multiple modules can
    stack contributions onto the same variable without fighting.
- `wlib.envRef :: name -> envRef`: marker used inside `values` /
  `prefix` / `suffix` lists to reference another env variable at
  runtime. Dropped cleanly if the referenced variable is unset.
- `wlib.renderEnvString :: env -> str`: pure helper that renders an
  `env` attrset into the shell snippet the wrapper uses. Exposed
  for testing and downstream composition.
- `outputs.staticEnv`: subset of `env` that resolves to a plain
  literal string, used by the systemd integration.
- `wrapper.nix` injects `"$@"` into args at order 1001, controllable
  via the ordering system.
- `outputs.wrapper` as the canonical output path (config.wrapper is
  a backward-compatible alias).
