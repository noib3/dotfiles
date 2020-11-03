" Define (re)inclusion guard
if exists('b:shell_folds_loaded')
  finish
endif
let b:shell_folds_loaded = 1

setlocal foldmethod=expr
setlocal foldexpr=ShellFoldsExpr(v:lnum)
setlocal foldtext=ShellFoldsText()

function! ShellFoldsExpr(lnum) " {{{1
  let line = getline(a:lnum)

  " Fold multiline array definitions like
  " FOO=(
  "   bar
  "   baz
  " )
  " if line =~ '.*=($' | return 'a1' | endif

  " Fold multiline function definitions like
  " foo() {
  "   echo "bar baz"
  " }
  if line =~ '.*()\s*{$' | return 'a1' | endif

  " Close folds
  if line =~ '^\s*\(}\|)\).*$' | return 's1' | endif

  " Return current fold level
  return '='
endfunction " }}}1

function! ShellFoldsText() "{{{1
  let line = getline(v:foldstart)

  let fold_title = substitute(line, '^\s*', '', '')

  " Remove =(
  " let fold_title = substitute(fold_title, '=(\s*$', '', '')

  " Remove {
  let fold_title = substitute(fold_title, '\s*{\s*$', '', '')

  return folding#FoldsTextFormat(fold_title)
endfunction " }}}1

" vim:fdm=marker
