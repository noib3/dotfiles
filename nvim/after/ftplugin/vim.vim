" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
set formatoptions-=o
set formatoptions-=j
" set formatoptions-=crql

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Text displayed on folded lines
setlocal foldtext=MarkerFoldsText()

" Display vertical columns at 80 and 100 characters
execute "set cc=" . (&cc == "" ? "80,100" : "")

" Fold text for marker folds
function! MarkerFoldsText()
  let comment_char = substitute(&commentstring, '\s*%s', '', '')
  " The first substitute extracts the text between the commentstring and the
  " markers without leading spaces, the second one removes trailing spaces. It
  " could probably be done with a single substitute but idk how.
  let fold_title = substitute(getline(v:foldstart),
                              \ comment_char.'\s*\(.*\){\{3}\d*',
                              \ '\1',
                              \ '')
  let fold_title = substitute(fold_title, '\s*$', '', '')
  let dashes = repeat(v:folddashes, 2)
  let fold_size = v:foldend - v:foldstart + 1

  let fill_num = 68 - len(dashes . fold_title . fold_size)

  return '+' . dashes . ' ' . fold_title . ' ' . repeat('·', fill_num)
          \ . ' ' . fold_size . ' lines'
endfunction
