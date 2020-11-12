function fuzzy_edit --description "Fuzzy search a file in ~ and open \
it in $EDITOR"
  set -l filenames (echo "~/"(string escape -- (fzf --multi --height=8)) |
                    tr "\n" " " | sed 's/\s$//') \
  && commandline $EDITOR" "$filenames \
  && commandline -f execute
  commandline -f repaint
end
