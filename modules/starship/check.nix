{
  pkgs,
  self,
}:

let
  starshipWrapped =
    (self.wrapperModules.starship.apply {
      inherit pkgs;

      settings = {
        add_newline = false;
        character = {
          success_symbol = "[>](bold green)";
        };
      };

    }).wrapper;

in
pkgs.runCommand "starship-test" { } ''

  export STARSHIP_CACHE="$TMPDIR"
  "${starshipWrapped}/bin/starship" --version | grep -q "starship"

  touch $out
''
