# Opens today's todo file (<documentsDir>/tdtd/<yyyy>-<mm>-<dd>.md), creating
# it first if it doesn't already exist.

local DOCUMENTS_DIR="$1"

filepath="${DOCUMENTS_DIR}/tdtd/$(date +%Y-%m-%d).md"
[[ -f "$filepath" ]] || touch "$filepath"
$EDITOR "$filepath"
