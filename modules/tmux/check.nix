{
  pkgs,
  self,
}:

let
  tmuxWrapped =
    (self.wrapperModules.tmux.apply {
      inherit pkgs;
      "tmux.conf".content = ''
        set -g status-justify absolute-centre
      '';
    }).wrapper;
in
pkgs.runCommand "tmux-test" { } ''
  "${tmuxWrapped}/bin/tmux" display-message -p '#{config_files}' | grep -q 'tmux.conf'
  touch $out
''
