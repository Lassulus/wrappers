# wrappers

A Nix library to create wrapped executables via the module system.

Are you annoyed by rewriting modules for every platform? nixos, home-manager, nix-darwin, devenv?

Then this library is for you!

[xkcd 927](https://xkcd.com/927/)

##

Watch this excellent Video by Vimjoyer for an explanation:

[![Homeless Dotfiles with Nix Wrappers](https://img.youtube.com/vi/Zzvn9uYjQJY/0.jpg)](https://www.youtube.com/watch?v=Zzvn9uYjQJY)


## Overview

This library provides two main components:

- `lib.wrapModule`: Function to create reusable wrapper modules with type-safe configuration options
  - And related, `lib.wrapPackage`: an alias for `(wrapModule ...).wrapper`
- `wrapperModules`: Pre-built wrapper modules for common packages (mpv, notmuch, etc.)

## Usage

### Using Pre-built Wrapper Modules

```nix
{
  inputs.wrappers.url = "github:lassulus/wrappers";

  outputs = { self, nixpkgs, wrappers }: {
    packages.x86_64-linux.default =
      wrappers.wrapperModules.mpv.wrap {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        scripts = [ pkgs.mpvScripts.mpris ];
        "mpv.conf".content = ''
          vo=gpu
          hwdec=auto
        '';
        "mpv.input".content = ''
          WHEEL_UP seek 10
          WHEEL_DOWN seek -10
        '';
      };
  };
}
```

### Creating Custom Wrapper Modules

```nix
{ wlib, lib }:

wlib.wrapModule ({ config, wlib, ... }: {
  options = {
    profile = lib.mkOption {
      type = lib.types.enum [ "fast" "quality" ];
      default = "fast";
      description = "Encoding profile to use";
    };
    outputDir = lib.mkOption {
      type = lib.types.str;
      default = "./output";
      description = "Directory for output files";
    };
  };

  config.package = config.pkgs.ffmpeg;
  config.flags = {
    "-preset" = if config.profile == "fast" then "veryfast" else "slow";
  };
  config.env = {
    FFMPEG_OUTPUT_DIR = config.outputDir;
  };
})
```

```nix
{ pkgs, wrappers, ... }:

(wrappers.lib.wrapModule {
  inherit pkgs;
  package = pkgs.curl;
  extraPackages = [ pkgs.jq ];
  env = {
    CURL_CA_BUNDLE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  };
  flags = {
    "--silent" = {};
    "--connect-timeout" = "30";
  };
  # Or use args for more control:
  # args = [ "--silent" "--connect-timeout" "30" ];
  flagSeparator = "=";  # Use --flag=value instead of --flag value (default is " ")
  wrap.args."--run" = ''
    echo "Making request..." >&2
  '';
}).wrapper # to get the package out of the module
```

## Technical Details

### wrapModule Function

Creates a reusable wrapper module.

Imports `wlib.modules.default` then evaluates the module. It then returns `.config` so that `.wrap` is easily accessible!

Use this when you want to quickly create a wrapper but without providing it a `pkgs` yet.

```nix
wrapModule = (wlib.evalModule wlib.modules.default).config.apply;
```

### wrapProgram Function

Imports `wlib.modules.default` then evaluates the module. It then returns the wrapped package.

Use this when you want to quickly create a wrapped package directly. Requires a `pkgs` to be set.

```nix
wrapModule = (wlib.evalModule wlib.modules.default).config.wrap;
```

### evalModule Function

- Type-safe configuration options via the module system
- `options`: Exposed options for documentation generation
- `apply`: Function to instantiate the wrapper with settings, returning a config object
  - Access the wrapped package via the `wrapper` attribute of the returned config

Built-in options (always available):
- `pkgs`: nixpkgs instance (required)
- `package`: Base package to wrap
- `aliases`: List of additional symlink names for the executable (default: `[]`)
- `extraPackages`: Additional runtime dependencies to add to PATH
- `flags`: Command-line flags (attribute set)
  - Value `{}`: Flag without argument (e.g., `--verbose`)
  - Value `"string"`: Flag with argument (e.g., `--output "file.txt"`)
  - Value `false` or `null`: Flag omitted
- `flagSeparator`: Separator between flag name and value (default: `" "`)
- `args`: Command-line arguments list (auto-generated from `flags` if not provided)
- `env`: Environment variables
- `passthru`: Additional passthru attributes
- `wrapper`: The resulting wrapped package (read-only, auto-generated from other options)
- `apply`: Function to extend the config with additional modules (read-only)
- `wrapperFunction`: wrapper function to be used to make the wrapper.
  - type: `{ config, wlib, ... /* other args from callPackage */ }` -> which returns a package
  - Returned package MUST contain `$out/bin/${binName}` as the executable to be wrapped.

The `wrapModule` function:
- Preserves all outputs from the original package (man pages, completions, etc.)
- Uses `lndir` for symlinking to maintain directory structure
- Generates a shell wrapper script with proper escaping
- Handles multi-output derivations correctly

Custom types:
- `wlib.types.file`: File type with `content` and `path` options
  - `content`: File contents as string
  - `path`: Derived path using `pkgs.writeText`

### mkWrapperFlagType and mkWrapperFlag

These functions define typed module options representing wrapper flags.

`mkWrapperFlagType n` creates a Nix type that validates flags expecting `n` arguments per instance.

`mkWrapperFlag n` builds a matching option definition with reasonable defaults (`false` for 0-arity, empty list otherwise).

They help ensure that wrapper argument modules are statically type-checked and compatible with `argOpts2list`.

They are used when defining the module used for options by the `makeWrapper` and `makeBinaryWrapper` `wrapperFunction` implementations

### argOpts2list

Converts a flat attribute set of wrapper argument options into a sequential list of command-line arguments.

Accepts a structure like `{ "--flag" = true; "--set" = [ [ "VAR" "VALUE" ] ]; }` and produces a linearized list suitable for `makeWrapper`.

Supports boolean flags (included or omitted), single-argument flags (lists of strings), and multi-argument flags (lists of fixed-length lists).

This is used by the `makeWrapper` and `makeBinaryWrapper` `wrapperFunction` implementations to gather wrapper arguments

### generateArgsFromFlags

Generates a list of arguments from a flags attribute set and a configurable flag separator.
Each key is treated as a flag name, and values determine how the flag appears:

* `true` → flag alone
* `false` or `null` → omitted
* list → repeated flags
* string → flag with value
  The separator determines spacing (`"--flag value"`) or joining (`"--flag=value"`).

It is the function that maps the `config.opts` module option to something that would work in the `config.args` option.

### Module System Integration

The wrapper module system integrates with NixOS module evaluation:
- Uses `lib.evalModules` for configuration evaluation
- Supports all standard module features (imports, conditionals, mkIf, etc.)
- Provides `config` for accessing evaluated configuration
- Provides `options` for introspection and documentation

### Extending Configurations

The `apply` function allows you to extend an already-applied configuration with additional modules, similar to `extendModules` in NixOS:

```nix
# Apply initial configuration
initialConfig = wrappers.wrapperModules.mpv.apply {
  pkgs = pkgs;
  scripts = [ pkgs.mpvScripts.mpris ];
  "mpv.conf".content = ''
    vo=gpu
  '';
};

# Extend with additional configuration
extendedConfig = initialConfig.apply {
  scripts = [ pkgs.mpvScripts.thumbnail ];
  "mpv.conf".content = ''
    profile=gpu-hq
  '';
};

# Access the wrapper
package = extendedConfig.wrapper;
```

The `apply` function re-evaluates the module with both the original settings and the new module, allowing you to override or add to the existing configuration.

## Example Modules

### mpv Module

Wraps mpv with configuration file support and script management:

```nix
wrappers.wrapperModules.mpv.wrap {
  pkgs = pkgs;
  scripts = [ pkgs.mpvScripts.mpris pkgs.mpvScripts.thumbnail ];
  "mpv.conf".content = ''
    vo=gpu
    profile=gpu-hq
  '';
  "mpv.input".content = ''
    RIGHT seek 5
    LEFT seek -5
  '';
  flags = {
    "--save-position-on-quit" = {};
  };
}
```

### notmuch Module

Wraps notmuch with INI-based configuration:

```nix
wrappers.wrapperModules.notmuch.wrap {
  pkgs = pkgs;
  config = {
    database = {
      path = "/home/user/Mail";
      mail_root = "/home/user/Mail";
    };
    user = {
      name = "John Doe";
      primary_email = "john@example.com";
    };
  };
}
```

## alternatives

- [wrapper-manager](https://github.com/viperML/wrapper-manager) by viperML. This project focuses more on a single module system, configuring wrappers and exporting them. This was an inspiration when building this library, but I wanted to have a more granular approach with a single module per package and a collection of community made modules.

## Long-term Goals

Upstream this schema into nixpkgs with an optional module.nix for every package. NixOS modules could then reuse these wrapper modules for consistent configuration across platforms.
