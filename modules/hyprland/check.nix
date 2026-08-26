{
  pkgs,
  self,
}:
let
  hyprlandWrapped =
    (self.wrapperModules.hyprland.apply {
      inherit pkgs;

      "hyprland.lua".content = ''
        hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
        hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
        hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
        hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
        hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
        hl.animation({
            leaf = "global",
            enabled = true,
            speed = 10,
            bezier = "default",
        })


      '';
    }).wrapper;
in
pkgs.runCommand "hypr-test" { } ''

  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  "${hyprlandWrapped}/bin/hyprland" --version | grep -q "${hyprlandWrapped.version}"

  touch $out
''
