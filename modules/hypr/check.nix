{
  pkgs,
  self,
}:

let
  hyprWrapped =
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

  "${hyprWrapped}/bin/hyprland" --version | grep -q "${hyprWrapped.version}"

  touch $out
''
