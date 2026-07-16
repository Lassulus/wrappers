{ config, lib, ... }: {
  _class = "wrapper";

  options = {
    settings = lib.mkOption {
      type =
        with lib.types;
        let
          atom = oneOf [
            str
            int
            bool
          ];
        in
        attrsOf (either (attrsOf atom) atom);
      default = { };
      description = "Default options passed to skim. See {manpage}`sk(1)`";
      example = {
        tabstop = 4;
        no-info = true;
        bind = {
          ctrl-d = "half-page-down";
          ctrl-u = "half-page-up";
        };
      };
    };
  };

  config = {
    package = lib.mkDefault config.pkgs.skim;

    env.SKIM_OPTIONS_FILE =
      let
        mkValueStringDefault = lib.generators.mkValueStringDefault { };

        generated = lib.generators.toKeyValue {
          mkKeyValue =
            k: v:
            if v == true then
              "--${k}"
            else
              let
                value =
                  if builtins.isAttrs v then
                    lib.escapeShellArg (lib.concatMapAttrsStringSep "," (k': v': "${k'}:${mkValueStringDefault v'}") v)
                  else if builtins.isString v then
                    lib.escapeShellArg v
                  else
                    mkValueStringDefault v;
              in
              "--${k} ${value}";
        } config.settings;
      in
      lib.pipe generated [
        (lib.replaceString "#" "##") # escape comments
        (config.pkgs.writeText "skim-options")
        builtins.toPath
      ];

    meta.maintainers = [ lib.maintainers.bandithedoge ];
  };
}
