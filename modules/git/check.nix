{
  pkgs,
  self,
}:

let
  gitWrapped =
    (self.wrapperModules.git.apply {
      inherit pkgs;
      settings = {
        user = {
          name = "Test User";
          email = "test@example.com";
        };
      };
    }).wrapper;

in
pkgs.runCommand "git-test" { } ''
  "${gitWrapped}/bin/git" --version | grep -q "git"
  touch $out
''
