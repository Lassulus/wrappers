{
  pkgs,
  self,
}:

let
  jujutsuWrapped =
    (self.wrapperModules.jujutsu.apply {
      inherit pkgs;
      settings = {
        user = {
          name = "Test User";
          email = "test@example.com";
        };
      };
    }).wrapper;
in
pkgs.runCommand "jujutsu-test" { } ''
  config_list="$(${jujutsuWrapped}/bin/jj config list --user)"
  [[ "$config_list" == *'user.name = "Test User"'* ]]
  [[ "$config_list" == *'user.email = "test@example.com"'* ]]
  touch $out
''
