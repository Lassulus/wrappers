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
        eval "$(zoxide init zsh --cmd cd)"
        eval "$(oh-my-posh init zsh)"
      '';
    }).wrapper;
in
pkgs.runCommand "zsh-test" { } ''
  "${zshWrapped}/bin/zsh"
  touch $out
''
