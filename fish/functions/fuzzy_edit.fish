function fuzzy_edit --description "Fuzzy search a file in ~ and open \
it in $EDITOR"
  set -l filename (fzf --height=8) \
  && commandline "$EDITOR ~/"(string escape -- $filename) \
  && commandline -f execute
  commandline -f repaint
end
