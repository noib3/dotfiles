case "$1" in
  -t|--tab)
    dmenu_prompt='Tpen> '
    open_command='open -t'
    ;;
  *)
    dmenu_prompt='Open> '
    open_command='open'
    ;;
esac

history="$(\
  sqlite3 -separator ' ' "$QUTE_DATA_DIR/history.sqlite" \
    'select title, url from CompletionHistory'\
)"

url="$(\
  echo "$history" \
    | tac \
    | dmenu-xembed-qute -l 7 -F -p "$dmenu_prompt" \
    | sed -E 's/[^ ]+ +//g' \
)"

[ -z "${url// }" ] && exit

echo "$open_command $url" >> "$QUTE_FIFO"
