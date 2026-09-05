if selection="$(
  printf "" |
    FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_ALT_C_OPTS-}" \
      fzf --bind "start:reload(${FZF_ALT_C_COMMAND})"
)"; then
  status=0
else
  status=$?
fi

if [ "$status" -eq 130 ] || [ -z "$selection" ]; then
  exit 0
fi

if [ "$status" -ne 0 ]; then
  exit "$status"
fi

case "$selection" in
  /*) printf '%s\n' "$selection" ;;
  *) printf '%s\n' "$HOME/$selection" ;;
esac
