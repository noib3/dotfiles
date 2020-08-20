" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
set formatoptions-=j

" Display vertical columns at 80 and 100 characters
execute "set cc=" . (&cc == "" ? "80,100" : "")
