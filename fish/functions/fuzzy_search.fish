function fuzzy_search --description "Fuzzy search a file in ~ and add it \
at the current cursor position"
  set -l filename (fzf --height=8) \
  && commandline -i "~/"(string replace -a " " "\\ " $filename)
  commandline -f repaint
end
