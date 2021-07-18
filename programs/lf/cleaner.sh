if [ -n "$UEBERZUG_FIFO" ]; then
  declare -A -p cmd=(\
    [action]=remove \
    [identifier]=preview \
  ) > "$UEBERZUG_FIFO"
fi
