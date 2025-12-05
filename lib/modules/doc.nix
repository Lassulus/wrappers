{
  options,
  config,
  lib,
  wlib,
  ...
}:
let
  internalOptions = lib.flatten (
    builtins.attrValues (
      builtins.mapAttrs (
        _: mod:
        builtins.attrNames
          (mod {
            lib = null;
            wlib = null;
            config = null;
            options = null;
          }).options
      ) wlib.modules
    )
  );
  optionsToRender = builtins.removeAttrs options config.docs.ignoreOptions;
  nixosOptionsDoc = config.pkgs.nixosOptionsDoc {
    options = optionsToRender;
    warningsAreErrors = config.docs.warningsAreErrors;
  };
in
{
  options.docs = {
    ignoreOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = internalOptions;
    };
    warningsAreErrors = lib.mkOption {
      type = lib.types.bool;
      default = false; # TODO make this true
      description = "Whether warnings during documentation generation should be treated as errors.";
    };
    asciiDoc = lib.mkOption {
      type = lib.types.package;
      default = nixosOptionsDoc.optionsAsciiDoc;
    };
    commonMark = lib.mkOption {
      type = lib.types.package;
      default = nixosOptionsDoc.optionsCommonMark;
    };
    json = lib.mkOption {
      type = lib.types.package;
      default = nixosOptionsDoc.optionsJSON;
    };
  };
}
