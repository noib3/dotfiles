" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
setlocal formatoptions-=t

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Override some options set by UltiSnips in ultisnips/ftplugin/snippets.vim
setlocal foldmethod=manual
setlocal foldlevel=0

" Text displayed on folded lines
setlocal foldtext=folding#MarkerFoldsText()
