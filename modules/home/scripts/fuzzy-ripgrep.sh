if git status &>/dev/null; then
  cd "$(git rev-parse --show-toplevel)" || exit
fi

results="$(
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
)"
status=$?

if [ "$status" -eq 130 ] || [ -z "$results" ]; then
  exit 0
fi

if [ "$status" -ne 0 ]; then
  exit "$status"
fi

regex='^([^:]*):([^:]*):([^:]*):.*$'

mapfile -t filenames < <(echo -n "$results" | sed -r "s!$regex!\1!;s/\ /\\\ /g")
lnum="$(echo "$results" | head -n 1 | sed -r "s/$regex/\2/")"
col="$(echo "$results" | head -n 1 | sed -r "s/$regex/\3/")"

nvim "+call cursor($lnum, $col)" "${filenames[@]}"
