function fuzzy_edit
  set -l filename (fzf --height=8) \
  && $EDITOR ~/"$filename" || true
end
