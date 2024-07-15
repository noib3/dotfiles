set -l filenames (
  fzf --multi --prompt='Edit> ' --preview='previewer ~/{}' \
    | sed 's/\ /\\\ /g;s!^!~/!' \
    | tr '\n' ' ' \
    | sed 's/[[:space:]]*$//'
)

test ! -z "$filenames" \
  && commandline "$EDITOR $filenames" \
  && commandline -f execute

commandline -f repaint
