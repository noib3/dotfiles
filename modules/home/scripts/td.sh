filepath="$DOCUMENTS/todos/$(date +%Y-%m-%d).md"
[[ -f $filepath ]] || touch "$filepath"
$EDITOR "$filepath"
