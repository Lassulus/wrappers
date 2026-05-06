{
  pkgs,
  self,
}:
let
  gitCliffWrapped =
    (self.wrapperModules.git-cliff.apply {
      inherit pkgs;
      settings = {
        changelog.trim = true;
        git.conventional_commits = true;
      };
    }).wrapper;
in
pkgs.runCommand "git-cliff-test" { } ''
  "${gitCliffWrapped}/bin/git-cliff" --version | grep -q "git-cliff"
  touch $out
''
