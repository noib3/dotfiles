" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
set formatoptions-=r
set formatoptions-=o

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Display vertical columns at 80 and 100 characters
execute "set cc=" . (&cc == "" ? "80,100" : "")

" Text displayed on folded lines
setlocal foldtext=vim#MarkerFoldsText()

" Disable pairing of double quotes
let b:coc_pairs_disabled = ['"']
