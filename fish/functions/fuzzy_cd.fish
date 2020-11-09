function fuzzy_cd --description "Fuzzy search a directory in ~ and cd into it"
  set -l dirname (eval (echo $FZF_ONLYDIR_COMMAND) | fzf --height=8) \
  && cd ~/$dirname
  commandline -f repaint
end
