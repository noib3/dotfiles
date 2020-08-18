" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" The following file was taken as a starting point for this one:
"   https://github.com/petobens/dotfiles/blob/master/vim/ftplugin/tex/folding.vim

" In the following comments and definitions a section is a generic term for any
" sectioning command (\part{}, \subsection{}, etc.), not just a literal \section{}

" Define (re)inclusion guard
if exists('b:LaTeXFolds_loaded')
  finish
endif
let b:LaTeXFolds_loaded = 1

setlocal foldmethod=expr
setlocal foldexpr=LaTeXFoldsExpr(v:lnum)
setlocal foldtext=LaTeXFoldsText()

" Sections to be folded
if !exists('g:LaTeXFolds_fold_sections')
  let g:LaTeXFolds_fold_sections = [
    \ 'part',
    \ 'chapter',
    \ 'section',
    \ 'subsection',
    \ 'subsubsection'
    \ ]
endif

" Optimize by predefining common patterns
let s:folded = '^\s*\\\(' . join(g:LaTeXFolds_fold_sections, '\|') . '\(\*\)\?\|end{document}\)'

" LaTeXFoldsExpr helper function {{{

" This function returns the sections that are to be folded and their corresponding fold level
function! s:ParseFoldSections()
  " Initialize
  let fold_sections = []
  let fold_level = 1

  " If this variable is set to 1 don't search the section in the file and just
  " add it to fold_sections
  let dont_search_add_section = 0

  " Ignore unused section commands: if there's no 'part' then 'chapter' should
  " have the highest fold level, if there's no 'chapter' then 'section' should
  " have the highest fold level, and so on
  for section in g:LaTeXFolds_fold_sections
    " This is the pattern that we look for and the one we add to the
    " fold_sections list. We also match 0 or 1 occurences of an asterisk after
    " a section (\chapter{} or \chapter*{}) with \(\*\)\?
    let section_pattern = '^\s*\\' . section . '\(\*\)\?{.*}\s*$'
    if dont_search_add_section
      call insert(fold_sections, [section_pattern, fold_level])
      let fold_level += 1
    else
      let i = 1
      while i < line('$')
        if getline(i) =~# section_pattern
          call insert(fold_sections, [section_pattern, fold_level])
          let fold_level += 1
          let dont_search_add_section = 1
          break
        endif
        let i += 1
      endwhile
    endif
  endfor

  return fold_sections
endfunction

" }}}

" LaTeXFoldsExpr {{{

" Get all the found sections with their fold level
let s:found_sections_levels = s:ParseFoldSections()

function! LaTeXFoldsExpr(lnum)
  " Get this line and the next one
  let this_line = getline(a:lnum)
  let next_line = getline(a:lnum + 1)

  " Check for normal lines first
  if this_line !~# s:folded
    " A blank line before \end{document} or before a fold level less then or
    " equal to the current one is left unfolded
    if this_line =~# '^\s*$' && next_line =~# s:folded
      if next_line =~# '^\s*\\end{document}\s*$'
        return 0
      else
        for [section_pattern, fold_level] in s:found_sections_levels
          if next_line =~# section_pattern
            " I don't understand why I get what I want with <= instead of >=
            " Even < without the = works, it doesn't make sense
            if foldlevel(a:lnum - 1) <= fold_level
              return fold_level - 1
            else
              return "="
            endif
          endif
        endfor
      endif
    else
      return "="
    endif
  endif

  " Fold sections
  for [section_pattern, fold_level] in s:found_sections_levels
    if this_line =~# section_pattern
      return ">".fold_level
    endif
  endfor

  " Return the fold level of the previous line
  " Only the last line with \end{document} should get this far
  return "="
endfunction

" }}}

" LaTeXFoldsText {{{

function! LaTeXFoldsText()

  let section = substitute(getline(v:foldstart), '.*\\\(.*\){.*', '\u\1', '')
  let section_title = substitute(getline(v:foldstart), '.*{\(.*\)}.*', '\1', '')
  let dashes = repeat(v:folddashes, 2)
  let fold_size = v:foldend - v:foldstart + 1

  let fill_num = 66 - strchars(dashes . section . section_title . fold_size)

  return '+' . dashes . ' ' . section . ': ' . section_title . ' '
          \ . repeat('·', fill_num) . ' ' . fold_size . ' lines'
endfunction

" }}}

" vim: set foldmethod=marker:
