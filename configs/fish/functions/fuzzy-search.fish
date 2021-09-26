set -l filenames (
  fzf --multi --prompt='Paste> ' --preview='previewer ~/{}' \
    | sed 's/\ /\\\ /g;s!^!~/!' \
    | tr '\n' ' ' \
    | sed 's/[[:space:]]*$//'
)

test -z "$filenames" || commandline --insert "$filenames"
commandline -f repaint
