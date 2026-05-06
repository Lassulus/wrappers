{
  config,
  lib,
  wlib,
  ...
}:
let
  # imported from home-manager
  # https://github.com/nix-community/home-manager/blob/5a9efa93c586f79e80b0ad7d8036c450f53c3d1d/modules/lib/generators.nix#L4

  toHyprconf =
    {
      attrs,
      indentLevel ? 0,
      importantPrefixes ? [ "$" ],
    }:
    let
      inherit (lib)
        all
        concatMapStringsSep
        concatStrings
        concatStringsSep
        filterAttrs
        foldl
        generators
        hasPrefix
        isAttrs
        isList
        mapAttrsToList
        replicate
        attrNames
        ;

      initialIndent = concatStrings (replicate indentLevel "  ");

      toHyprconf' =
        indent: attrs:
        let
          isImportantField =
            n: _: foldl (acc: prev: if hasPrefix prev n then true else acc) false importantPrefixes;
          importantFields = filterAttrs isImportantField attrs;
          withoutImportantFields = fields: removeAttrs fields (attrNames importantFields);

          allSections = filterAttrs (_n: v: isAttrs v || isList v) attrs;
          sections = withoutImportantFields allSections;

          mkSection =
            n: attrs:
            if isList attrs then
              let
                separator = if all isAttrs attrs then "\n" else "";
              in
              (concatMapStringsSep separator (a: mkSection n a) attrs)
            else if isAttrs attrs then
              ''
                ${indent}${n} {
                ${toHyprconf' "  ${indent}" attrs}${indent}}
              ''
            else
              toHyprconf' indent { ${n} = attrs; };

          mkFields = generators.toKeyValue {
            listsAsDuplicateKeys = true;
            inherit indent;
          };

          allFields = filterAttrs (_n: v: !(isAttrs v || isList v)) attrs;
          fields = withoutImportantFields allFields;
        in
        mkFields importantFields
        + concatStringsSep "\n" (mapAttrsToList mkSection sections)
        + mkFields fields;
    in
    toHyprconf' initialIndent attrs;
in
{
  _class = "wrapper";

  options = {
    settings = lib.mkOption {
      type =
        with lib.types;
        let
          valueType =
            nullOr (oneOf [
              bool
              int
              float
              str
              path
              (attrsOf valueType)
              (listOf valueType)
            ])
            // {
              description = "Hyprlock configuration value";
            };
        in
        valueType;

      default = { };

      description = ''
        Hyprlock configuration written in Nix. Entries with the same key should
        be written as lists. Variable names and colors should be quoted. See
        <https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/> for more examples.
      '';
    };

    importantPrefixes = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "$"
        "bezier"
        "monitor"
        "size"
      ];

      description = ''
        List of important prefixes to source at the top of the config.
      '';
    };

    sourceFirst = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to put source entries at the top of the configuration.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to `hyprlock.conf`.
      '';
    };
  };

  config.env =
    let
      hyprlockConf =
        (lib.optionalString (config.settings != { }) (toHyprconf {
          attrs = config.settings;
          importantPrefixes = config.importantPrefixes ++ lib.optional config.sourceFirst "source";
        }))
        + lib.optionalString (config.extraConfig != "") config.extraConfig;

      # create directory structure that matches ~/.config/hypr/hyprlock.conf
      configDir = config.pkgs.runCommand "hyprlock-config" { } ''
        mkdir -p $out/hypr
        cp ${config.pkgs.writeText "hyprlock.conf" hyprlockConf} $out/hypr/hyprlock.conf
      '';
    in
    {
      XDG_CONFIG_DIRS = "${configDir}";
    };

  config.package = config.pkgs.hyprlock;
  config.meta.platforms = lib.platforms.linux;

  config.meta.maintainers = [
    {
      name = "cooukiez";
      github = "cooukiez";
      githubId = 61082023;
    }
  ];
}
