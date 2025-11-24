{
  config,
  lib,
  wlib,
  ...
}:
let
  gitIniFmt = config.pkgs.formats.gitIni { };
in
{
  _class = "wrapper";

  options = {
    settings = lib.mkOption {
      type = gitIniFmt.type;
      default = { };
      description = ''
        Git configuration settings.
        See {manpage}`git-config(1)` for available options.
      '';
    };

    configFile = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = toString (gitIniFmt.generate "gitconfig" config.settings);
      description = "Generated git configuration file.";
    };
  };

  config.env.GIT_CONFIG_GLOBAL = config.configFile.path;

  config.package = config.pkgs.git;

  config.meta.maintainers = [
    {
      name = "adeci";
      github = "adeci";
      githubId = 80290157;
    }
  ];
  config.meta.platforms = lib.platforms.all;
}
