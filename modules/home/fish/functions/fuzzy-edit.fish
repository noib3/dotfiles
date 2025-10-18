if git status &>/dev/null
  set ROOT (git rev-parse --show-toplevel)
else
  set ROOT "$HOME"
end

set -l filenames (
  lf-recursive "$ROOT" \
    | fzf --multi --prompt="Edit> " --preview="preview $ROOT/{}" \
    | sed "s/\ /\\\ /g;s!^!$ROOT/!" \
    | tr '\n' ' ' \
    | sed 's/[[:space:]]*$//'
)

test ! -z "$filenames" \
  && commandline "$EDITOR $filenames" \
  && commandline -f execute

commandline -f repaint
