dow=$(date +%u)
monday=$(date -d "$((1 - dow)) days" +%Y-%m-%d)
sunday=$(date -d "$((7 - dow)) days" +%Y-%m-%d)
filepath="$DOCUMENTS/todos/$monday--$sunday.md"
[[ -f $filepath ]] || touch "$filepath"
$EDITOR "$filepath"
