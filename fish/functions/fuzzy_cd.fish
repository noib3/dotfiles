function fuzzy_cd --description "Fuzzy search a directory in ~ and cd into it"
  set -l dirname (
    eval (echo $FZF_ONLYDIR_COMMAND) | fzf --prompt="Cd> " --height=8
  ) \
    && cd $HOME/$dirname
  commandline -f repaint
end
