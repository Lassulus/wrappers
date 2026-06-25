{
  config,
  lib,
  wlib,
  ...
}:
let
  formatLine =
    n: v:
    let
      formatValue = v: if lib.isBool v then (if v then "true" else "false") else toString v;
    in
    ''set ${n}	"${formatValue v}"'';

  formatMapLine = n: v: "map ${n}   ${toString v}";
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.str
          lib.types.bool
          lib.types.int
          lib.types.float
        ]
      );
      default = { };
      description = ''
        Add {option}`:set` command options to zathura and make
        them permanent. See
        {manpage}`zathurarc(5)`
        for the full list of options.
      '';
      example = {
        default-bg = "#000000";
        default-fg = "#FFFFFF";
      };
    };
    mappings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Add {option}`:map` mappings to zathura and make
        them permanent. See
        {manpage}`zathurarc(5)`
        for the full list of possible mappings.

        You can create a mode-specific mapping by specifying the mode before the key:
        `"[normal] <C-b>" = "scroll left";`
      '';
      example = {
        D = "toggle_page_mode";
        "<Right>" = "navigate next";
        "[fullscreen] <C-i>" = "zoom in";
      };
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Additional commands for zathura that will be added to the
        {file}`zathurarc` file.
      '';
    };
    "zathurarc" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      description = "zathura config file";
      default.content =
        lib.concatStringsSep "\n" (
          lib.optional (config.extraConfig != "") config.extraConfig
          ++ lib.mapAttrsToList formatLine config.settings
          ++ lib.mapAttrsToList formatMapLine config.mappings
        )
        + "\n";
    };
    extraFiles = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "File name in the config directory";
            };
            file = lib.mkOption {
              type = wlib.types.file config.pkgs;
              description = "File or path to add into the config directory";
            };
          };
        }
      );
      default = [ ];
      description = "Additional files to be placed in the config directory";
    };
  };
  config = {
    flags = {
      "--config-dir" = toString (
        config.pkgs.linkFarm "zathura-merged-config" (
          let
            entry = name: path: { inherit name path; };
          in
          [ (entry "zathurarc" config."zathurarc".path) ]
          ++ (map (f: {
            inherit (f) name;
            path = f.file.path;
          }) config.extraFiles)
        )
      );
    };
    package = config.pkgs.zathura;
    meta = {
      maintainers = [
        {
          name = "holly";
          github = "hollymlem";
          githubId = 35699052;
        }
      ];
    };
  };
}
