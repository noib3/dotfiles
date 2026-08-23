if git status &>/dev/null; then
  cd "$(git rev-parse --show-toplevel)" || exit
fi

if results="$(
  rg-pattern "" |
    fzf \
      --multi \
      --prompt='Rg> ' \
      --disabled \
      --delimiter=':' \
      --with-nth='1,2,4..' \
      --bind="change:reload:rg-pattern {q}" \
      --preview='rg-preview {1}:{2}' \
      --preview-window='+{2}-/2'
)"; then
  status=0
else
  status=$?
fi

if [ "$status" -eq 130 ] || [ -z "$results" ]; then
  exit 0
fi

if [ "$status" -ne 0 ]; then
  exit "$status"
fi

regex='^([^:]*):([^:]*):([^:]*):.*$'

mapfile -t locations < <(
  printf '%s\n' "$results" | sed -r "s!$regex!\1:\2:\3!"
)

"$EDITOR" -- "${locations[@]}"
