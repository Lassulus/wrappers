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

### Added

- `lib/modules/command.nix`: base module with shared command spec
  (args, env, hooks, exePath) used by both wrapper and systemd outputs.
- `lib/modules/flags.nix`: flags module with per-flag ordering via
  `{ value, order }` submodules. Default order is 1000. Reading
  `config.flags` returns clean values (order is transparent).
- `wrapper.nix` injects `"$@"` into args at order 1001, controllable
  via the ordering system.
- `outputs.wrapper` as the canonical output path (config.wrapper is
  a backward-compatible alias).
