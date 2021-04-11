setlocal foldtext=folds#marker_folds_extract_title()
setlocal formatoptions-=ro
setlocal iskeyword-=#
setlocal matchpairs+=<:>

let b:surround_{char2nr('z')} = "\" \1Title: \1 {{{\n\r\n\" }}}"
