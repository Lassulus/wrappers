{ lib }:
let
  /**
    The canonical base16 slot names.

    The base16 specification spells the hex digit in upper case (`base0A`, not
    `base0a`), but scheme files in the wild are inconsistent about it. Parsed
    keys are lower-cased and looked up in `bySlug` to normalise them.
  */
  slots = [
    "base00"
    "base01"
    "base02"
    "base03"
    "base04"
    "base05"
    "base06"
    "base07"
    "base08"
    "base09"
    "base0A"
    "base0B"
    "base0C"
    "base0D"
    "base0E"
    "base0F"
  ];

  bySlug = lib.listToAttrs (map (slot: lib.nameValuePair (lib.toLower slot) slot) slots);

  # Matches `base0A: "#fabd2f" # yellow` as well as the older flat `base0A: fabd2f`.
  colorLine = ''^[[:space:]]*(base[0-9a-fA-F]{2})[[:space:]]*:[[:space:]]*"?#?([0-9a-fA-F]{6})"?.*$'';

  # Matches a top level `variant: "dark"` / `name: "Gruvbox dark, hard"`,
  # tolerating both quoting and a trailing comment.
  metaLine = key: ''^[[:space:]]*${key}[[:space:]]*:[[:space:]]*"?([^"#]*[^" #])"?.*$'';

  /**
    Normalise a single colour to lower case 6 digit hex without a `#` prefix,
    which is how palettes are stored throughout the styling module.
  */
  normalizeColor =
    name: value:
    let
      matched = builtins.match "#?([0-9a-fA-F]{6})" (toString value);
    in
    if matched == null then
      throw "styling: ${name} is not a 6 digit hex colour, got ${toString value}"
    else
      lib.toLower (builtins.head matched);

  /**
    Normalise an attrset palette, dropping keys that are not base16 slots.

    Unknown keys are ignored rather than rejected so that base24 schemes
    (which add `base10`..`base17`) can be passed through unchanged. A typo is
    still caught, by `requireSlots` reporting the resulting missing slot.
  */
  normalizePalette =
    attrs:
    lib.listToAttrs (
      lib.concatMap (
        entry:
        let
          key = lib.toLower entry.name;
        in
        lib.optional (bySlug ? ${key}) (
          lib.nameValuePair bySlug.${key} (normalizeColor entry.name entry.value)
        )
      ) (lib.mapAttrsToList lib.nameValuePair attrs)
    );

  requireSlots =
    source: palette:
    let
      missing = lib.filter (slot: !(palette ? ${slot})) slots;
    in
    if missing == [ ] then
      palette
    else
      throw "styling: ${source} is missing base16 colours: ${lib.concatStringsSep ", " missing}";

  /**
    Parse a base16 scheme from the text of a YAML file.

    This is a deliberately small line based parser rather than a real YAML
    parser: it only understands the shape base16 schemes actually take, which
    keeps scheme loading pure. Using a YAML tool would require import from
    derivation, and CI runs `nix flake check`.

    Handles both the current tinted-theming layout (a nested `palette:` block
    with `#` prefixed, quoted values and trailing comments) and the older flat
    layout. Verified against all 303 schemes in `pkgs.base16-schemes`.

    # Type

    ```
    parseScheme :: String -> { palette :: AttrsOf String, variant :: Null | String, name :: Null | String }
    ```
  */
  parseScheme =
    text:
    let
      lines = lib.splitString "\n" text;

      palette = lib.listToAttrs (
        lib.concatMap (
          line:
          let
            matched = builtins.match colorLine line;
          in
          if matched == null then
            [ ]
          else
            let
              key = lib.toLower (builtins.head matched);
            in
            lib.optional (bySlug ? ${key}) (
              lib.nameValuePair bySlug.${key} (lib.toLower (lib.elemAt matched 1))
            )
        ) lines
      );

      meta =
        key:
        lib.foldl' (
          acc: line:
          let
            matched = builtins.match (metaLine key) line;
          in
          if matched == null then acc else builtins.head matched
        ) null lines;
    in
    {
      inherit palette;
      variant = meta "variant";
      name = meta "name";
    };

  /**
    Resolve the value of `styling.scheme` into a parsed scheme.

    Accepts:

    - a path or derivation holding a base16 YAML file
    - a string containing `/`, treated as a path to a base16 YAML file
    - any other string, treated as a scheme name in `pkgs.base16-schemes`,
      e.g. `"gruvbox-dark-hard"`
    - an attrset of `base00`..`base0F` colours, with or without `#` prefixes

    Derivations are checked before attrsets because a derivation is also an
    attrset, and `pkgs.writeText` is a natural way to pass a scheme inline.

    # Type

    ```
    resolveScheme :: Pkgs -> (AttrsOf String | Path | Derivation | String) -> { palette; variant; name; }
    ```
  */
  resolveScheme =
    pkgs: scheme:
    let
      fromFile = source: parseScheme (builtins.readFile source);

      isFile = lib.isPath scheme || lib.isDerivation scheme;

      parsed =
        if isFile then
          fromFile scheme
        else if lib.isString scheme then
          if lib.hasInfix "/" scheme then
            fromFile scheme
          else
            fromFile "${pkgs.base16-schemes}/share/themes/${scheme}.yaml"
        else if lib.isAttrs scheme then
          {
            palette = normalizePalette scheme;
            variant = scheme.variant or null;
            name = scheme.name or null;
          }
        else
          throw "styling: cannot resolve a scheme of type ${builtins.typeOf scheme}";

      source =
        if isFile || lib.isString scheme then "scheme ${toString scheme}" else "the scheme attrset";
    in
    parsed // { palette = requireSlots source parsed.palette; };
in
{
  inherit
    slots
    parseScheme
    resolveScheme
    normalizeColor
    ;
}
