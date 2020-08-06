" Filename:   nvim/ftplugin/tex/folding.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

function! TeXFolds()
  return "0"
endfunction

setlocal foldmethod=expr
setlocal foldexpr=TeXFolds()
