" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
set formatoptions+=a
set formatoptions-=r
set formatoptions-=o

" Display vertical columns at 80 and 100 characters
execute 'set cc=' . (&cc == '' ? '80,100' : '')
