" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

function! folding#MarkerFoldsText() " {{{1
  let line = getline(v:foldstart)
  let comment_char = substitute(&commentstring, '\s*%s', '', '')

  " The first substitute extracts the fold_title, i.e. the text between the
  " commentstring and the markers (the three curly braces), without leading
  " spaces, while the second one removes any trailing spaces.  It can probably
  " be done with a single substitute but idk how.
  let fold_title = substitute(line,
                              \ comment_char . '\s*\(.*\){\{3}\d*\s*',
                              \ '\1',
                              \ '')
  let fold_title = substitute(fold_title, '\s*$', '', '')

  return folding#FoldsTextFormat(fold_title)
endfunction " }}}1

function! folding#FoldsTextFormat(fold_title) " {{{1
  let fold_title = a:fold_title

  " Set the column where the last character of the fold's text should be
  let last_foldtext_column = 78
  " Add two dashes for every fold level
  let dashes = repeat(v:folddashes, 2)
  " Calculate how many lines there are in the fold
  let fold_size = v:foldend - v:foldstart + 1

  " Calculate how many filler characters should be displayed
  let fill_num = last_foldtext_column
                 \ - strchars('+' . dashes . ' ' . fold_title .
                              \ ' ' . ' ' . fold_size . ' lines')

  " If the fold title isn't too long append a space. If it is, cut the fold
  " title short and add three dots at the end of it.
  if fill_num >= 0
    let fold_title .= ' '
  else
    let fold_title = substitute(fold_title,
                                \ '\(.*\)\(.\{' . (abs(fill_num) + 2) . '\}\)',
                                \ '\1...',
                                \ '')
  endif

  return '+' . dashes . ' ' . fold_title .
          \ repeat('·', fill_num) . ' ' . fold_size . ' lines'
endfunction " }}}1

" vim:fdm=marker
