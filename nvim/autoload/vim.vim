" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

function! vim#MarkerFoldsText() " {{{1
  let comment_char = substitute(&commentstring, '\s*%s', '', '')

  " The first substitute extracts the text between the commentstring and the
  " markers without leading spaces, the second one removes trailing spaces. It
  " can probably be done with a single substitute but idk how.
  let fold_title = substitute(getline(v:foldstart),
                              \ comment_char.'\s*\(.*\){\{3}\d*\s*',
                              \ '\1',
                              \ '')
  let fold_title = substitute(fold_title, '\s*$', '', '')

  let dashes = repeat(v:folddashes, 2)
  let fold_size = v:foldend - v:foldstart + 1
  let fill_num = 68 - strchars(dashes . fold_title . fold_size)

  return '+' . dashes . ' ' . fold_title . ' '
           \ . repeat('·', fill_num) . ' ' . fold_size . ' lines'
endfunction " }}}1

" vim: set foldmethod=marker:
