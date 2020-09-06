" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" In the following comments and definitions a section is a generic term for any
" sectioning command like \part{..} or \subsection{..}, not just a literal
" \section{..}.

" The two functions s:clear_texorpdfstring() and s:find_closing() were taken
" from the vimtex's plugin, specifically from autoload/vimtex/parser/toc.vim

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
    \ 'subsubsection',
    \ ]
endif

" Option to fold preamble
if !exists('g:LaTeXFolds_fold_preamble')
  let g:LaTeXFolds_fold_preamble = 1
endif

" Option to use the section numbers from the vimtex's plugin in the section
" title.
if !exists('g:LaTeXFolds_use_vimtex_section_numbers')
  let g:LaTeXFolds_use_vimtex_section_numbers = 1
endif

" Join all section names in a single regex, including potential asterisks for
" starred sections (e.g. \chapter*{..}).
let s:sections_regex = '^\s*\\\(' . join(g:LaTeXFolds_fold_sections, '\|') . '\)'
                                \ . '\s*\(\*\)\?\s*{\(.*\)}\s*$'

function! s:find_sections() " {{{1
  " This function finds which sections in g:LaTeXFolds_fold_sections are
  " actually present in the document, and returns a dictionary where the keys
  " are the section names and the values are their foldlevel in the document.

  let fold_levels = {}

  let level = 1
  for section in g:LaTeXFolds_fold_sections
    let i = 1
    while i <= line('$')
      if getline(i) =~# '^\s*\\' . section . '\s*\(\*\)\?\s*{.*'
        let fold_levels[section] = level
        let level += 1
        break
      endif
      let i += 1
    endwhile
  endfor

  return fold_levels
endfunction " }}}1

" s:find_sections() returns a dictionary where the keys are the section names
" and the values are their foldlevel in the document.
let s:fold_levels = s:find_sections()

function! LaTeXFoldsExpr(lnum) " {{{1
  let line = getline(a:lnum)

  " If the line is blank return the fold level of the previous or the next
  " line, whichever is the lowest.
  if line =~ '^\s*$' | return '-1' | endif

  " Let \begin{document} and \end{document} remain unfolded
  if line =~# '^\s*\\\(begin\|end\)\s*{document}' | return '0' | endif

  " Fold the preamble
  if g:LaTeXFolds_fold_preamble == 1 && line =~# '^\s*\\documentclass'
    return '>1'
  endif

  " If this is a 'regular' line, return the fold level of the previous line
  if line !~# s:sections_regex | return '=' | endif

  " If I get here it means the line contains a sectioning command. Find which
  " one it is and return its fold level.
  let line_section = substitute(line, s:sections_regex, '\1', '')
  return '>' . s:fold_levels[line_section]
endfunction " }}}1

function! LaTeXFoldsText() "{{{1
  let line = getline(v:foldstart)

  " Get the section title, and if it contains any \texorpdfstring's extract
  " their first argument.
  let section_title = substitute(line, s:sections_regex, '\3', '')
  if section_title =~# '\\texorpdfstring'
    let section_title = s:clear_texorpdfstring(section_title)
  endif

  if g:LaTeXFolds_use_vimtex_section_numbers == 1
    " If the vimtex plugin is loaded use it to get the section numbers, if not
    " display an error message and use two question marks as the section
    " numbers.
    if exists('*vimtex#toc#new')
      let section_num = s:get_section_num(v:foldstart)
    else
      echohl ErrorMsg
      echomsg '[folding.vim] vimtex not loaded'
      echohl None
      let section_num = '??'
    endif
    " If the section number isn't empty insert two spaces before the title
    let fold_title = empty(section_num)
                     \ ? section_title
                     \ : section_num . '  ' . section_title
  else
    " Get the section name, capitalizing its first letter and including
    " potential asterisks for starred sections (e.g. \chapter*{...}).
    let section_name = substitute(line, s:sections_regex, '\u\1\2', '')
    let fold_title = section_name . ': ' . section_title
  endif

  " If I'm folding the preamble and the line contains a \documentclass, just
  " set fold_title to 'Preamble'.
  if g:LaTeXFolds_fold_preamble == 1 && line =~# '^\s*\\documentclass'
    let fold_title = 'Preamble'
  endif

  " Set the column where the last character of the fold's text should be
  let last_foldtext_column = 78
  " Add two dashes for every fold level
  let dashes = repeat(v:folddashes, 2)
  " Calculate how many lines there are in the fold
  let fold_size = v:foldend - v:foldstart + 1

  " Calculate how many filler characters should be displayed
  let fill_num = last_foldtext_column
                 \ - strchars('+' . dashes . ' ' . fold_title . ' ' . fold_size . ' lines')
                 \ - 1

  " If the fold title isn't too long append a space. If it is, cut the fold
  " title short and add three dots at the end of it.
  if fill_num >= 0
    let fold_title .= ' '
  elseif fill_num < -1
    let fold_title = substitute(fold_title,
                                \ '\(.*\)\(.\{' . (abs(fill_num) + 2) . '\}\)',
                                \ '\1...',
                                \ '')
  endif

  return '+' . dashes . ' ' . fold_title . repeat('·', fill_num) . ' ' . fold_size . ' lines'
endfunction " }}}1

" Helper functions {{{1

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
endfunction " }}}2

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
endfunction " }}}2

" https://github.com/lervag/vimtex/issues/1776#issuecomment-687820220 {{{2

let s:cache = {
      \ 'toc_updated': 0,
      \ 'file_updated': {},
      \ }

function! s:get_section_num(lnum) abort
  if !has_key(s:cache, 'toc')
    let s:cache.toc = vimtex#toc#new({
        \ 'name' : 'Fold text ToC',
        \ 'layers' : ['content'],
        \ 'refresh_always' : 0,
        \ })
  endif

  let l:file = expand('%')
  let l:ftime = getftime(l:file)

  if l:ftime > get(s:cache.file_updated, l:file) || localtime() > s:cache.toc_updated + 300
    call s:cache.toc.get_entries(1)
    let s:cache.toc_entries = filter(
          \ s:cache.toc.get_visible_entries(),
          \ '!empty(v:val.number)')
    let s:cache.file_updated[l:file] = l:ftime
    let s:cache.toc_updated = localtime()
  endif

  let l:entries = filter(deepcopy(s:cache.toc_entries), 'v:val.line == a:lnum')
  if len(l:entries) > 1
    call filter(l:entries, "v:val.file ==# expand('%:p')")
  endif

  return empty(l:entries) ? '' : s:cache.toc.print_number(l:entries[0].number)
endfunction

" }}}2

" }}}1

" vim:fdm=marker
