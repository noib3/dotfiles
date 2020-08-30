" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
setlocal formatoptions+=a
setlocal formatoptions-=r
setlocal formatoptions-=o

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Display vertical columns at 80 and 100 characters
execute 'set cc=' . (&cc == '' ? '80,100' : '')

" Autopair less-than with greater-than signs
let g:AutoPairs['<'] = '>'

" Text displayed on folded lines
setlocal foldtext=vim#MarkerFoldsText()
