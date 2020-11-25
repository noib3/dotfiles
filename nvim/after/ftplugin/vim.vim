setlocal formatoptions-=ro

setlocal iskeyword-=#

setlocal foldtext=folding#MarkerFoldsText()

let b:surround_{char2nr("z")} = "\" \1Title: \1 {{{\n\n\r\n\n\" }}}"
