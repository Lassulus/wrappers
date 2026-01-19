{
  pkgs,
  self,
}:
let
  zshWrapped =
    (self.wrapperModules.zsh.apply {
      inherit pkgs;
      settings = {
        keyMap = "emacs";
        shellAliases = {
          nvim = "nix run ~/nixos-config";
          hdon = "hyprctl dispatch dpms on";
          ls = "eza --icons";
        };
        env = {
          NH_OS_FLAKE = "~/nixos-config";
        };
        history = {
          append = true;
          expanded = true;
          ignoreSpace = true;
          saveNoDups = true;
          ignoreDups = true;
        };
      };
      extraRC = ''
        echo "test"
        which setopt
      '';
    }).wrapper;
in
pkgs.runCommand "zsh-test" { } ''
    "${zshWrapped}/bin/zsh"
    ZDOTDIR=$(${zshWrapped}/bin/zsh -c "echo \$ZDOTDIR")
  ${zshWrapped}/bin/zsh -c "source $ZDOTDIR/.zshenv; source $ZDOTDIR/.zshrc"
  touch $out
''
