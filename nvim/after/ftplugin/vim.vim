" Filename:   nvim/ftplugin/vim.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Display vertical columns at 80 and 100 characters
execute "set cc=" . (&cc == "" ? "80,100" : "")
