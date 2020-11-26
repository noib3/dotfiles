function fuzzy_edit --description "Fuzzy search a file in ~ and open \
it in $EDITOR"
  set --local filenames (fzf --prompt="Edit> " --multi --height=8) \
  && set --local filenames (
    echo "~/"(string escape -- $filenames) | tr "\n" " " | sed 's/\s$//'
  ) \
  && commandline $EDITOR" "$filenames \
  && commandline --function execute
  commandline --function repaint
end
