{
  wlib,
  lib,
  ...
}:
wlib.wrapModule ({
  config,
  lib,
  ...
}: let
  aliasesstr = lib.concatMapAttrsStringSep "/n" (k: v: "alias -- ${k}=${v}") config.settings.shellAliases;
in {
  options = {
    settings = {
      history = {};
      shellAliases = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = {};
      };
    };
  };
  config = let
    zshConfigDir = config.pkgs.linkFarmFromDrvs "zsh-config-directory" [
      aliasesstr
    ];
  in {
    package = config.pkgs.zsh;
    env.Z_DOT_DIR = "${zshConfigDir}";
    meta = {
      maintainers = [
        {
          name = "mrid22";
          github = "mrid22";
          githubId = 80290157;
        }
      ];
      platforms = lib.platforms.all;
    };
  };
})
