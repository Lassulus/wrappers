{
  pkgs,
  self,
}:

let
  tmuxWrapped =
    (self.wrapperModules.tmux.apply {
      inherit pkgs;
      statusKeys = "vi";
      modeKeys = "vi";
      vimVisualKeys = true;
    }).wrapper;

in
pkgs.runCommand "rofi-test" { } ''
  res="${tmuxWrapped}/bin/tmux"

  if ! grep -q -- '-f' "$res"; then
    echo "-f flag not found in tmux wrapper"
    touch $out
    exit 1
  fi

  if ! grep -q -- 'tmux.conf' "$res"; then
    echo "tmux.conf not found in tmux wrapper"
    touch $out
    exit 1
  fi

  touch $out
''
