function fuzzy_search --description "Fuzzy search a file in ~ and add it \
at the current cursor position"
  set -l filenames (echo "~/"(string escape -- (fzf --multi --height=8)) |
                    tr "\n" " " | sed 's/\s$//') \
  && commandline -i $filenames
  commandline -f repaint
end
