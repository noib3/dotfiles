dow=$(date +%u)
monday=$(date -d "$((8 - dow)) days" +%Y-%m-%d)
sunday=$(date -d "$((14 - dow)) days" +%Y-%m-%d)
filepath="$DOCUMENTS/todos/$monday--$sunday.md"
[[ -f $filepath ]] || touch "$filepath"
$EDITOR "$filepath"
