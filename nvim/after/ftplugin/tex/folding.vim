" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" The following file was taken as a starting point for this one:
"   https://github.com/petobens/dotfiles/blob/master/vim/ftplugin/tex/folding.vim
"
" Also, the two functions s:clear_texorpdfstring() and s:find_closing() were
" taken from the vimtex's plugin, specifically from autoload/vimtex/parser/toc.vim
"
" In the following comments and definitions a section is a generic term for any
" sectioning command like \part{} or \subsection{}, not just a literal
" \section{}.

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

function! LaTeXFoldsExpr(lnum) " {{{1
  " Get this line and the next one
  let this_line = getline(a:lnum)
  let next_line = getline(a:lnum + 1)

  " Find all the sections and their fold level
  let found_sections_levels = s:ParseFoldSections()

  " Check for normal lines first
  if this_line !~# s:folded
    " A blank line before \end{document} or before a fold level less then or
    " equal to the current one is left unfolded
    if this_line =~# '^\s*$' && next_line =~# s:folded
      if next_line =~# '^\s*\\end{document}\s*$'
        return 0
      else
        for [section_pattern, fold_level] in found_sections_levels
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
  for [section_pattern, fold_level] in found_sections_levels
    if this_line =~# section_pattern
      return ">".fold_level
    endif
  endfor

  " Return the fold level of the previous line
  " Only the last line with \end{document} should get this far
  return "="
endfunction
" }}}1

function! LaTeXFoldsText() "{{{1
  " Extract the section, making sure that starred sections are handled
  " correctly, and capitalize the first letter (chapter -> Chapter).
  let section = substitute(getline(v:foldstart),
                           \ '^\s*\\\(' . join(g:LaTeXFolds_fold_sections, '\(\*\)\?\|') . '\){.*',
                           \ '\u\1',
                           \ '')

  " Escape possible asterisks in the section before using it as a regex
  let escaped_section = substitute(section, '\*', '\\\*', '')
  let section_title = substitute(getline(v:foldstart),
                                 \ '^\s*\\' . escaped_section . '{\(.*\)}\s*$',
                                 \ '\1',
                                 \ '')

  " Check if the section title contains one or more \texorpdfstring commands.
  " If it does, extract their first argument.
  if section_title =~# '\\texorpdfstring'
    let section_title = s:clear_texorpdfstring(section_title)
  endif

  let dashes = repeat(v:folddashes, 2)
  let fold_size = v:foldend - v:foldstart + 1
  let fill_num = 66 - strchars(dashes . section . section_title . fold_size)

  return '+' . dashes . ' ' . section . ': ' . section_title . ' '
          \ . repeat('·', fill_num) . ' ' . fold_size . ' lines'
endfunction
" }}}1

" Helper functions {{{1

function! s:ParseFoldSections() " {{{2
  " This function returns the sections that are to be folded and their
  " corresponding fold level.
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
" }}}2

function! s:clear_texorpdfstring(title) abort " {{{2
  " We only want the TeX string:
  "
  " > \texorpdfstring{TEXstring}{PDFstring}

  let l:i1 = match(a:title, '\\texorpdfstring')
  if l:i1 < 0 | return a:title | endif

  " Find start of included part
  let l:i2 = match(a:title, '{', l:i1+1)
  if l:i2 < 0 | return a:title | endif

  " Find end of included part
  let [l:i3, l:dummy] = s:find_closing(l:i2+1, a:title, 1, '{')
  if l:i3 < 0 | return a:title | endif

  " Find start, then end of excluded part
  let l:i4 = match(a:title, '{', l:i3+1)
  if l:i4 < 0 | return a:title | endif
  let [l:i4, l:dummy] = s:find_closing(l:i4+1, a:title, 1, '{')

  return strpart(a:title, 0, l:i1)
        \ . strpart(a:title, l:i2+1, l:i3-l:i2-1)
        \ . s:clear_texorpdfstring(strpart(a:title, l:i4+1))
endfunction
" }}}2

function! s:find_closing(start, string, count, type) abort " {{{2
  if a:type ==# '{'
    let l:re = '{\|}'
    let l:open = '{'
  else
    let l:re = '\[\|\]'
    let l:open = '['
  endif
  let l:i2 = a:start-1
  let l:count = a:count
  while l:count > 0
    let l:i2 = match(a:string, l:re, l:i2+1)
    if l:i2 < 0 | break | endif

    if a:string[l:i2] ==# l:open
      let l:count += 1
    else
      let l:count -= 1
    endif
  endwhile

  return [l:i2, l:count]
endfunction
" }}}2

" }}}1

" vim: set foldmethod=marker:
