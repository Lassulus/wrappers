{
  config,
  wlib,
  lib,
  ...
}:
let
  # implements kdl with niri semantic knowledge to convert the data-format
  inherit
    (rec {
      #allow modifiers to be set for blocks
      leftpad = v: lib.strings.concatMapStrings (v: "  ${v}\n") (lib.strings.splitString "\n" v);
      mkBlock =
        n: v:
        let
          attrs = if builtins.isAttrs n then (n._attrs or "") else "";
          formattedAttrs =
            if builtins.isAttrs attrs then
              lib.concatMapAttrsStringSep " " (k: v: "${k}=${toVal v}") attrs
            else if attrs != "" then
              # string attrs must be quoted
              ''"${attrs}"''
            else
              "";
          body = lib.optionalString (v != "") ''
            {
            ${leftpad v}
            }
          '';
        in
        ''
          ${n.name or n} ${formattedAttrs} ${body}
        '';
      # surround strings with quotes
      toVal =
        v:
        if lib.isString v then
          ''"${v}"''
        else if lib.isBool v then
          (if v then "true" else "false")
        else
          toString v;
      mkKeyVal =
        k: v: "${k} ${if lib.isList v then lib.strings.concatStringsSep " " (map toVal v) else toVal v}";
      attrsToKdl =
        a:
        lib.concatMapAttrsStringSep "\n" (
          n: v:
          # turn null values into flags
          if builtins.isNull v then
            n
          else if lib.isAttrs v then
            #move attrs to name and continue recursively building the kdl
            if v._keys or false then
              "${n} ${
                (lib.concatMapAttrsStringSep " " (key: val: "${key}=${toVal val}") (lib.removeAttrs v [ "_keys" ]))
              }\n"
            else
              mkBlock {
                name = n;
                _attrs = v._attrs or "";
              } (attrsToKdl (lib.removeAttrs v [ "_attrs" ]))
          else if lib.isList v && lib.all lib.isAttrs v then
            mkBlock n (lib.concatMapStringsSep "\n" attrsToKdl v)
          else
            mkKeyVal n v
        ) a;
      mkTagged = tag: attrs: "${tag} ${lib.concatMapAttrsStringSep " " (k: v: "${k}=${toVal v}") attrs}";
      mkRule =
        block: r:
        let
          matches = map (mkTagged "match") r.matches or [ ];
          excludes = map (mkTagged "exclude") r.excludes or [ ];
          misc = attrsToKdl (
            lib.attrsets.removeAttrs r [
              "matches"
              "excludes"
            ]
          );
        in
        mkBlock block (
          lib.strings.concatLines (
            lib.lists.flatten [
              matches
              excludes
              misc
            ]
          )
        );
      mkWorkspaces =
        w:
        map attrsToKdl (
          lib.mapAttrsToList (n: v: {
            # use the attr name as attribute for the workspace node
            workspace =
              if v != null then
                {
                  _attrs = n;
                }
                // v
              else
                n;
          }) w
        );
      mkOutputs =
        w:
        map attrsToKdl (
          lib.mapAttrsToList (n: v: {
            # use the attr name as attribute for the workspace node
            output = {
              _attrs = n;
            }
            // v;
          }) w
        );
    })
    attrsToKdl
    mkRule
    mkWorkspaces
    mkOutputs
    ;
in
{
  _class = "wrapper";
  imports = [ wlib.modules.systemd ];
  options = {
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrs;
        options = {
          binds = lib.mkOption {
            default = { };
            type = lib.types.attrs;
            description = "Bindings of niri";
            example = {
              "Mod+T" = {
                spawn-sh = "alacritty";
                _attrs = {
                  repeat = false;
                };
              };
              "Mod+J".focus-column-or-monitor-left = null;
              "Mod+N".spawn = [
                "alacritty"
                "msg"
                "create-windown"
              ];
              "Mod+0".focus-workspace = 0;
            };
          };
          layout = lib.mkOption {
            default = { };
            type = lib.types.attrs;
            description = "Layout definitions";
            example = {
              focus-ring.off = null;
              border = {
                width = 3;
                active-color = "#f5c2e7";
                inactive-color = "#313244";
              };
            };
          };
          spawn-at-startup = lib.mkOption {
            default = [ ];
            type = lib.types.listOf (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
            description = ''
              List of commands to run at startup.
              The first element in a passed list will be run with the following elements as arguments
            '';
            example = [
              "hello"
              [
                "nix"
                "build"
              ]
            ];
          };
          window-rules = lib.mkOption {
            default = [ ];
            type = lib.types.listOf lib.types.attrs;
            description = "List of window rules";
            example = [
              {
                matches = [ { app-id = ".*"; } ];
                excludes = [
                  { app-id = "org.keepassxc.KeePassXC"; }
                ];
                open-focused = false;
                open-floating = false;
              }
            ];
          };
          layer-rules = lib.mkOption {
            default = [ ];
            type = lib.types.listOf lib.types.attrs;
            description = "List of layer rules";
            example = [
              {
                matches = [ { namespace = "^notifications$"; } ];
                block-out-from = "screen-capture";
                opacity = 0.8;
              }
            ];
          };
          workspaces = lib.mkOption {
            default = { };
            type = lib.types.attrsOf (lib.types.nullOr lib.types.anything);
            description = "Named workspace definitons";
            example = {
              "foo" = {
                open-on-output = "DP-3";
              };
              "bar" = null;
            };
          };
          outputs = lib.mkOption {
            default = { };
            type = lib.types.attrs;
            description = "Output configuration";
            example = {
              "DP-3" = {
                background-color = "#003300";
                position = {
                  _attrs = {
                    x = 0;
                    y = 0;
                  };
                };
                hot-corners = {
                  off = null;
                };
              };
            };
          };
          extraConfig = lib.mkOption {
            default = "";
            type = lib.types.str;
            description = ''
              Escape hatch string option added to the config file for
              options that might not be representable otherwise
            '';
          };
        };
      };
    };
    "config.kdl" =
      let
        compiledConfig = lib.strings.concatLines (
          lib.lists.flatten [
            # (attrsToKdl { inherit (config.settings) binds layout; })
            (map (mkRule "window-rule") config.settings.window-rules)
            (map (mkRule "layer-rule") config.settings.layer-rules)
            (map (
              v:
              (lib.strings.concatStringsSep " " (
                lib.lists.flatten [
                  "spawn-at-startup"
                  (map (v: ''"${v}"'') (lib.flatten [ v ]))
                ]
              ))
              + "\n"
            ) config.settings.spawn-at-startup)
            (mkWorkspaces config.settings.workspaces)
            (mkOutputs config.settings.outputs)
            (attrsToKdl (
              lib.removeAttrs config.settings [
                "window-rules"
                "layer-rules"
                "spawn-at-startup"
                "workspaces"
                "outputs"
                "extraConfig"
              ]
            ))
            config.settings.extraConfig
          ]
        );
        checkedConfig = config.pkgs.writeTextFile {
          name = "niri.kdl";
          text = compiledConfig;
          checkPhase = ''
            ${lib.getExe config.package} validate -c $out
          '';
        };
      in
      lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.path = checkedConfig;
        description = ''
          Configuration file for Niri.
          See <https://github.com/YaLTeR/niri/wiki/Configuration:-Introduction>
        '';
        example = ''
          input {
            keyboard {
                numlock
            }

            touchpad {
                tap
                natural-scroll
            }
          }
        '';
      };
  };
  # Drop the upstream user unit; we ship our own (below) with ExecReload
  # wired up to the niri IPC. Keep the desktop entry patched so display
  # managers still pick up the wrapper's binary.
  config.filesToExclude = [
    "lib/systemd/user/niri.service"
    "share/systemd/user/niri.service"
  ];
  config.filesToPatch = [
    "share/applications/*.desktop"
  ];
  config.package = config.pkgs.niri;

  # Shell-launched wrapper: same behaviour as upstream -- niri reads the
  # immutable, build-pinned config straight from /nix/store.
  config.env.NIRI_CONFIG = toString config."config.kdl".path;

  # Systemd-launched session: bootstrap a mutable runtime copy under
  # $XDG_RUNTIME_DIR (systemd specifier %t) and point niri at it via
  # `--config`. ExecReload re-stamps that file with the latest immutable
  # snapshot and asks niri to re-read it via IPC, so config-only switches
  # apply without dropping the session.
  config.systemd = {
    description = "A scrollable-tiling Wayland compositor";
    bindsTo = [ "graphical-session.target" ];
    before = [
      "graphical-session.target"
      "xdg-desktop-autostart.target"
    ];
    wants = [
      "graphical-session-pre.target"
      "xdg-desktop-autostart.target"
    ];
    after = [ "graphical-session-pre.target" ];
    serviceConfig = {
      Slice = "session.slice";
      Type = "notify";
      ExecStartPre = "${config.pkgs.coreutils}/bin/install -Dm644 ${config."config.kdl".path} %t/niri/config.kdl";
      ExecStart = "${config.exePath} --session --config %t/niri/config.kdl";
      ExecReload = [
        "${config.pkgs.coreutils}/bin/install -Dm644 ${config."config.kdl".path} %t/niri/config.kdl"
        "${config.exePath} msg action load-config-file"
      ];
    };
    # Tell NixOS's switch-to-configuration to convert every "needs
    # restart" verdict into `systemctl --user reload niri.service`, so
    # config-only switches reload the live session via ExecReload instead
    # of killing it. The flag is read out of the unit's [Service] section
    # at switch time (X-ReloadIfChanged=true).
    reloadIfChanged = true;
  };
  config.meta.maintainers = [
    lib.maintainers.zimward
    {
      name = "turbio";
      github = "turbio";
      githubId = 1428207;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
