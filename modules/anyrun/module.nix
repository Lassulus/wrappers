{
  config,
  lib,
  wlib,
  ...
}:
{
  imports = [ wlib.modules.systemd ];

  options =
    let
      fileType = wlib.types.file config.pkgs;
    in
    {
      "config.ron" = lib.mkOption {
        type = fileType;
        default.content = "";
      };

      "style.css" = lib.mkOption {
        type = fileType;
        default.content = "";
      };

      extraConfigFiles = lib.mkOption {
        type = lib.types.attrsOf fileType;
        default = { };
        description = "Additional files placed in the configuration directory";
        example = {
          "applications.ron".content = ''
            Config(
              desktop_actions: false,
              max_entries: 5,
            )
          '';
        };
      };

      plugins = lib.mkOption {
        type = with lib.types; listOf path;
        default = [ ];
        description = "List of shared objects that export Anyrun plugins. Overrides the `plugins` field in `config.ron`.";
        example = lib.literalExpression ''
          [
            "$\{pkgs.anyrun}/lib/libapplications.so"
          ]
        '';
      };
    };

  config =
    let
      configDir = toString (
        config.pkgs.linkFarm "anyrun-config" (
          let
            extraConfigFiles = lib.mapAttrsToList (name: file: {
              inherit name;
              inherit (file) path;
            }) config.extraConfigFiles;
          in
          [
            {
              name = "config.ron";
              inherit (config."config.ron") path;
            }
            {
              name = "style.css";
              inherit (config."style.css") path;
            }
          ]
          ++ extraConfigFiles
        )
      );
    in
    {
      package = config.pkgs.anyrun;

      args = [
        "--config-dir"
        configDir
      ]
      ++ lib.flatten (
        map (plugin: [
          "--plugins"
          plugin
        ]) config.plugins
      );

      systemd = {
        description = "Anyrun daemon";
        serviceConfig = {
          Type = "simple";
          ExecStart = "${config.exePath} --config-dir ${configDir} daemon";
          Restart = "on-failure";
          KillMode = "process";
        };
      };

      meta = {
        maintainers = [ lib.maintainers.bandithedoge ];
        platforms = lib.platforms.linux;
      };
    };
}
