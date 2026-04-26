filepath="$DOCUMENTS/todos/$(date -d tomorrow +%Y-%m-%d).md"
[[ -f $filepath ]] || touch "$filepath"
$EDITOR "$filepath"
