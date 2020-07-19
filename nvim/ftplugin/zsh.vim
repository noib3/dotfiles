" Filename:   nvim/ftplugin/zsh.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

" Display vertical columns at 80 and 100 characters
execute "set cc=" . (&cc == "" ? "80,100" : "")
