{
  pkgs,
  self,
}:

let
  kittyWrapped =
    (self.wrapperModules.kitty.apply {
      inherit pkgs;

      settings = {
        font_size = 12;
        cursor_text_color = "#111111";
      };

      extraSettings = ''
        cursor_shape block
      '';
    }).wrapper;

in
pkgs.runCommand "kitty-test" { } ''

  "${kittyWrapped}/bin/kitty" --version | grep -q "${kittyWrapped.version}"

  touch $out
''
