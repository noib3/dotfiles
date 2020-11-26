function fuzzy_search --description "Fuzzy search a file in ~ and add it \
to the commandline at the current cursor position"
  set --local filenames (fzf --prompt="Paste> " --multi --height=8) \
  && set --local filenames (
    echo "~/"(string escape -- $filenames) | tr "\n" " " | sed 's/\s$//'
  ) \
  && commandline --insert $filenames
  commandline --function repaint
end
