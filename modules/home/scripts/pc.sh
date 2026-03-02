filepath="$DOCUMENTS/punchclock/$(date +%Y).md"
mkdir -p "$(dirname "$filepath")"
[[ -f "$filepath" ]] || touch "$filepath"
$EDITOR "$filepath"
