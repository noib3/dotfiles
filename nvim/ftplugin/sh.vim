" Filename:   sh.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

execute "set cc=" . (&cc == "" ? "80,100" : "")

set makeprg=sh\ %
" set errorformat=%f:%l:\ %m

nmap <buffer> <silent> <C-t> :make<cr>
