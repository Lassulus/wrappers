{ pkgs, self }:
let
  anyrunWrapped =
    (self.wrapperModules.anyrun.apply {
      inherit pkgs;
      "config.ron".path = pkgs.anyrun + "/share/doc/anyrun/examples/config.ron";
      "style.css".path = pkgs.anyrun + "/share/doc/anyrun/examples/style.css";
    }).wrapper;
in
pkgs.runCommand "anyrun-test" { nativeBuildInputs = [ anyrunWrapped ]; } ''
  anyrun -V | grep ${anyrunWrapped.version}
  touch $out
''
