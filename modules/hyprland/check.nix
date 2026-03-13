{
  pkgs,
  self,
}:

let
  hyprlandWrapped =
    (self.wrapperModules.hyprland.apply {
      inherit pkgs;

      "hypr.conf".content = ''

        dwindle {
          pseudotile = yes
          preserve_split = yes
          special_scale_factor = 0.95
        }

        general {
          layout = dwindle
        }

      '';
    }).wrapper;

in
pkgs.runCommand "hypr-test" { } ''

  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  "${hyprlandWrapped}/bin/hyprland" --version | grep -q "${hyprlandWrapped.version}"

  touch $out
''
