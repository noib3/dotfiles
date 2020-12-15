function fuzzy_search --description "Fuzzy search a file in ~ and add it \
to the commandline at the current cursor position"
  set -l filenames (fzf --prompt="Paste> " --multi --height=8) \
    && set -l filenames (
      echo "~/"(string escape -- $filenames) | tr "\n" " " | sed 's/\s$//'
    ) \
    && commandline --insert $filenames
  commandline --function repaint
end
