set -e

if [ -n "$DISPLAY" ]; then
  export UEBERZUG_FIFO="${TMPDIR:-/tmp}/fzf-ueberzug-$$"

  cleanup() {
    exec 3>&-
    rm "$UEBERZUG_FIFO"
  }

  mkfifo "$UEBERZUG_FIFO"
  ueberzug layer --parser bash --silent <"$UEBERZUG_FIFO" &
  exec 3>"$UEBERZUG_FIFO"
  trap cleanup EXIT

  fzf \
    --preview 'previewer ~/{}' \
    --preview-window border-left \
    --bind "change:execute-silent(cleaner)" \
    --bind "ctrl-k:execute-silent(cleaner)+up" \
    --bind "ctrl-p:execute-silent(cleaner)+up" \
    --bind "up:execute-silent(cleaner)+up" \
    --bind "ctrl-j:execute-silent(cleaner)+down" \
    --bind "ctrl-n:execute-silent(cleaner)+down" \
    --bind "down:execute-silent(cleaner)+down" \
    --bind "pgup:execute-silent(cleaner)+page-up" \
    --bind "pgdn:execute-silent(cleaner)+page-down" \
    --bind "enter:execute-silent(cleaner)+accept" \
    --bind "double-click:execute-silent(cleaner)+accept" \
    --bind "ctrl-c:execute-silent(cleaner)+abort" \
    --bind "ctrl-g:execute-silent(cleaner)+abort" \
    --bind "ctrl-q:execute-silent(cleaner)+abort" \
    --bind "esc:execute-silent(cleaner)+abort" \
    "$@" 3>&-
else
  exec fzf "$@"
fi
