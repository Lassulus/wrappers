{
  wlib,
  lib,
  ...
}:
wlib.wrapModule (
  { config, wlib, ... }:
  let
    nvimPlugin = lib.types.either lib.types.package (
      lib.types.submodule {
        options = {
          plugin = lib.mkPackageOption config.pkgs.vimPlugins "plugin" {
            default = null;
            example = "pkgs.vimPlugins.nvim-treesitter";
            pkgsText = "pkgs.vimPlugins";
          };

          config = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            description = "Script to configure this plugin. The scripting language should match type.";
            default = null;
          };

          optional = lib.mkEnableOption "optional" // {
            description = "Don't load by default (load with :packadd)";
          };
        };
      }
    );

    rcDir = if lib.pathIsDirectory config.rc.path then config.rc.path else dirOf config.rc.path;
    nvimRtp = config.pkgs.stdenv.mkDerivation {
      name = "nvim-rtp";
      src = rcDir;

      buildPhase = ''
        mkdir -p $out/nvim
        mkdir -p $out/lua
        rm init.lua
      '';

      installPhase = ''
        # Copy nvim/lua only if it exists
        if [ -d "lua" ]; then
            cp -r lua $out/lua
            rm -r lua
        fi
        # Copy nvim/after only if it exists
        if [ -d "after" ]; then
            cp -r after $out/after
            rm -r after
        fi
        # Copy rest of nvim/ subdirectories only if they exist
        if [ ! -z "$(ls -A)" ]; then
            cp -r -- * $out/nvim
        fi
      '';
    };

    normalizedPlugins = config.pkgs.neovimUtils.normalizePlugins config.plugins;
    myVimPackage = config.pkgs.neovimUtils.normalizedPluginsToVimPackage normalizedPlugins;
    packdir = config.pkgs.neovimUtils.packDir {
      inherit myVimPackage;
    };
    pluginRC = lib.concatStringsSep "\n" (
      lib.foldl (acc: p: if p.config != null then acc ++ [ p.config ] else acc) [ ] normalizedPlugins
    );

    luaPackages =
      if config.package != config.pkgs.neovim-unwrapped then
        config.pkgs.neovim-unwrapped.lua.pkgs
      else
        config.package.lua.pkgs;
    resolvedExtraLuaPackages = config.extraLuaPackages luaPackages;

    getDeps = attrname: map (plugin: plugin.${attrname} or (_: [ ]));
    requiredPlugins = config.pkgs.vimUtils.requiredPluginsForPackage myVimPackage;
    pluginPython3Packages = getDeps "python3Dependencies" requiredPlugins;
    python3Env = config.pkgs.python3.pkgs.python.withPackages (
      ps:
      [ ps.pynvim ] ++ (config.extraPython3Packages ps) ++ (lib.concatMap (f: f ps) pluginPython3Packages)
    );
    python3Package = config.pkgs.writeShellApplication {
      name = "python3-wrapped-neovim";
      text = ''
        unset PYTHONPATH
        unset PYTHONSAFEPATH

        exec "${python3Env.interpreter}"  "$@" 
      '';
    };
  in
  {
    options = {
      rc = lib.mkOption {
        type = wlib.types.file config.pkgs;
        description = ''
          Your neovim rc.
          Can either be a string or the path to a nvim directory, in which case the entire directory gets wrapped.
        '';
      };

      plugins = lib.mkOption {
        type = lib.types.listOf nvimPlugin;
        default = [ ];
        example = lib.literalExpression ''
          with pkgs.vimPlugins; [
            nvim-treesitter.withAllGrammars
            oil-nvim
            { plugin = lualine;
              config = 'require('lualine').setup()'
            }
          ]
        '';
        description = ''
          List of neovim plugins to install.
        '';
      };

      extraLuaPackages = lib.mkOption {
        type = lib.types.functionTo (lib.types.listOf lib.types.package);
        default = _: [ ];
        defaultText = lib.literalExpression "ps: [ ]";
        example = lib.literalExpression "luaPkgs: with luaPkgs; [ luautf8 ]";
        description = ''
          The extra Lua packages required for your plugins to work.
          This option accepts a function that takes a Lua package set as an argument,
          and selects the required Lua packages from this package set.
          See the example for more info.
        '';
      };

      extraPython3Packages = lib.mkOption {
        type = lib.types.functionTo (lib.types.listOf lib.types.package);
        default = _: [ ];
        defaultText = lib.literalExpression "ps: [ ]";
        example = lib.literalExpression "pyPkgs: with pyPkgs; [ python-language-server ]";
        description = ''
          The extra Python 3 packages required for your plugins to work.
          This option accepts a function that takes a Python 3 package set as an argument,
          and selects the required Python 3 packages from this package set.
          See the example for more info.
        '';
      };
    };

    config.rc.content = lib.mkDefault ''
      -- prepend lua directory
      vim.opt.rtp:prepend('${nvimRtp}/lua')

      -- {{{ init.lua
      ${builtins.readFile (rcDir + /init.lua)}
      -- }}}

      -- Prepend nvim and after directories to the runtimepath
      -- NOTE: This is done after init.lua,
      -- because of a bug in Neovim that can cause filetype plugins
      -- to be sourced prematurely, see https://github.com/neovim/neovim/issues/19008
      -- We prepend to ensure that user ftplugins are sourced before builtin ftplugins.
      vim.opt.rtp:prepend('${nvimRtp}/nvim')
      vim.opt.rtp:prepend('${nvimRtp}/after')
    '';

    config.flags = {
      "--cmd" = "set packpath^=${packdir} | set rtp^=${packdir}";
    };

    config.package = lib.mkDefault config.pkgs.neovim;

    config.env = {
      LUA_CPATH =
        lib.optionalString (resolvedExtraLuaPackages != [ ])
          ''${lib.concatMapStringsSep ";" luaPackages.getLuaCPath resolvedExtraLuaPackages}''
        + "\${LUA_CPATH:+;$LUA_CPATH}";
      LUA_PATH =
        lib.optionalString (resolvedExtraLuaPackages != [ ])
          ''${lib.concatMapStringsSep ";" luaPackages.getLuaPath resolvedExtraLuaPackages}''
        + "\${LUA_PATH:+;$LUA_PATH}";

      VIMINIT = "lua dofile('${
        config.pkgs.writeText "init.lua" (
          ''
            -- Changes the python3 executable to the one created by the wrapper
            -- This is done in the config file to overwrite the original packages's python3
            -- without changing the package directly
            vim.g.python3_host_prog = '${python3Package}/bin/python3-wrapped-neovim'
          ''
          + config.rc.content
          + lib.optionalString (pluginRC != "") ''
            -- Source vim plugin config
            vim.cmd.source "${config.pkgs.writeText "init.vim" pluginRC}"
          ''
        )
      }')";
    };

    config.meta.maintainers = [
      {
        name = "Keiro";
        github = "keirok";
        githubId = 225957852;
      }
    ];
  }
)
