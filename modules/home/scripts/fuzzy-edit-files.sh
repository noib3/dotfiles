if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  root="$HOME"
fi

cd "$root" || exit

if selected_files="$(
  lf-recursive . |
    fzf --multi --prompt='Edit> ' --preview='preview {}'
)"; then
  status=0
else
  status=$?
fi

if [ "$status" -eq 130 ] || [ -z "$selected_files" ]; then
  exit 0
fi

if [ "$status" -ne 0 ]; then
  exit "$status"
fi

while IFS= read -r filename; do
  printf '%s/%s\n' "$root" "$filename"
done <<<"$selected_files"
