{ lib, ... }:
{
  _file = "lib/modules/meta.nix";
  options.meta = {
    maintainers = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "name";
              };
              github = lib.mkOption {
                type = lib.types.str;
                description = "GitHub username";
              };
              githubId = lib.mkOption {
                type = lib.types.int;
                description = "GitHub id";
              };
              email = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "email";
              };
              matrix = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Matrix ID";
              };
            };
          }
        )
      );
      default = [ ];
    };
    platforms = lib.mkOption {
      type = lib.types.listOf (lib.types.enum lib.platforms.all);
      default = lib.platforms.all;
      description = "Supported platforms";
    };
  };
}
