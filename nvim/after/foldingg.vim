setlocal foldmethod=expr
setlocal foldexpr=LaTeXFoldsExpr(v:lnum)

" Sections to be folded
let g:LaTeXFolds_fold_sections = [
  \ 'part',
  \ 'chapter',
  \ 'section',
  \ 'subsection',
  \ 'subsubsection'
  \ ]

" Join all section names in a single regex, including potential asterisks for
" starred sections (e.g. \chapter*{..}).
let s:sections_regex = '^\s*\\\(' . join(g:LaTeXFolds_fold_sections, '\|') . '\){\(.*\)}\s*$'

function! s:find_sections()
  " This function finds which sections in g:LaTeXFolds_fold_sections are
  " actually present in the document, and returns a dictionary where the keys
  " are the section names and the values are their foldlevel in the document.

  let fold_levels = {}

  let level = 1
  for section in g:LaTeXFolds_fold_sections
    let i = 1
    while i <= line('$')
      if getline(i) =~# '^\s*\\' . section . '{.*'
        let fold_levels[section] = level
        let level += 1
        break
      endif
      let i += 1
    endwhile
  endfor

  return fold_levels
endfunction

" s:find_sections() returns a dictionary where the keys are the section names
" and the values are their foldlevel in the document.
let s:fold_levels = s:find_sections()

function! LaTeXFoldsExpr(lnum)
  let line = getline(a:lnum)

  " If the line is blank return the fold level of the previous or the next
  " line, whichever is the lowest.
  if line =~ '^\s*$' | return '-1' | endif

  " Let \begin{document} and \end{document} remain unfolded
  if line =~# '^\s*\\\(begin\|end\)\s*{document}' | return '0' | endif

  " If this is a 'regular' line, return the fold level of the previous line
  if line !~# s:sections_regex | return '=' | endif

  " If I get here it means the line contains a sectioning command. Find which
  " one it is and return its fold level.
  let line_section = substitute(line, s:sections_regex, '\1', '')
  return '>' . s:fold_levels[line_section]
endfunction
