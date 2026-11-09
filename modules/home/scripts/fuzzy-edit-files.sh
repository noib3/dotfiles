# The innermost jj or Git repo containing the current directory, or the home
# directory if there isn't one.
root="$PWD"
while [ -n "$root" ] && [ ! -e "$root/.jj" ] && [ ! -e "$root/.git" ]; do
  root="${root%/*}"
done
root="${root:-$HOME}"

cd "$root" || exit

if selected_files="$(
  list-files --frecent-first "$root" |
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

selected_paths=()

while IFS= read -r filename; do
  selected_paths+=("$root/$filename")
done <<<"$selected_files"

frecency add files "${selected_paths[@]}"
printf '%s\n' "${selected_paths[@]}"
