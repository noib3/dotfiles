" Filename:   vim.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

setlocal shiftwidth=2 tabstop=2

execute "set cc=" . (&cc == "" ? "80,100" : "")
