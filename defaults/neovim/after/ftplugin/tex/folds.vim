" The two functions s:clear_texorpdfstring() and s:find_closing() were taken
" from the vimtex's plugin, specifically from autoload/vimtex/parser/toc.vim

if expand("%:e") !=# "tex"
  finish
endif

if exists("b:LaTeXFolds_loaded")
  finish
endif
let b:LaTeXFolds_loaded = 1

setlocal foldmethod=expr
setlocal foldexpr=LaTeXFoldsExpr(v:lnum)
setlocal foldtext=LaTeXFoldsText()

if !exists("g:LaTeXFolds_sections")
  let g:LaTeXFolds_sections = [
    \ "part",
    \ "chapter",
    \ "section",
    \ "subsection",
    \ "subsubsection",
    \ ]
endif

if !exists("g:LaTeXFolds_fold_preamble")
  let g:LaTeXFolds_fold_preamble = 0
endif

if !exists("g:LaTeXFolds_use_vimtex_section_numbers")
  let g:LaTeXFolds_use_vimtex_section_numbers = 0
endif

let s:sections_regex =
  \ '^\s*'
  \  . '\\\(' . join(g:LaTeXFolds_sections, '\|') . '\)'
  \  . '\s*\(\*\)\?\s*{\(.*\)}\s*$'

function! s:find_sections() " {{{1
  " This function finds which sections in g:LaTeXFolds_sections are
  " actually present in the file, and returns a dictionary where the keys are
  " the sections it found and the values are their foldlevel.
  let l:fold_levels = {}
  let l:level = 1
  for section in g:LaTeXFolds_sections
    let i = 1
    while i <= line('$')
      if getline(i) =~# '^\s*\\' . section . '\s*\(\*\)\?\s*{.*'
        let l:fold_levels[section] = level
        let l:level += 1
        break
      endif
      let i += 1
    endwhile
  endfor
  return l:fold_levels
endfunction " }}}1

let s:fold_levels = s:find_sections()

function! LaTeXFoldsExpr(lnum) " {{{1
  let l:line = getline(a:lnum)

  " If the l:line is blank return the fold level of the previous or the next
  " l:line, whichever is the lowest.
  if l:line =~ '^\s*$' | return "-1" | endif

  " Let \begin{document} and \end{document} remain unfolded
  if l:line =~# '^\s*\\\(begin\|end\)\s*{document}' | return "0" | endif

  " Fold the preamble
  if g:LaTeXFolds_fold_preamble == 1 && l:line =~# '^\s*\\documentclass'
    return ">1"
  endif

  " If this is a 'regular' l:line, return the fold level of the previous l:line
  if l:line !~# s:sections_regex | return "=" | endif

  " If I get here it means the l:line contains a sectioning command. Find which
  " one it is and return its fold level.
  let l:line_section = substitute(l:line, s:sections_regex, '\1', '')
  return ">" . s:fold_levels[l:line_section]
endfunction " }}}1

function! LaTeXFoldsText() "{{{1
  let l:line = getline(v:foldstart)

  " Get the section title, and if it contains any \texorpdfstring's extract
  " their first argument.
  let l:section_title = substitute(l:line, s:sections_regex, '\3', '')
  if l:section_title =~# '\\texorpdfstring'
    let l:section_title = s:clear_texorpdfstring(section_title)
  endif

  if g:LaTeXFolds_use_vimtex_section_numbers == 1
    " If the vimtex plugin is loaded use it to get the section numbers, if not
    " display an error message and use two question marks as the section
    " numbers.
    if &runtimepath =~# 'vimtex'
     let l:section_num = s:get_section_num(v:foldstart)
    else
      echohl ErrorMsg
      echomsg "[LaTeXFolds] vimtex not loaded"
      echohl None
      let l:section_num = "??"
    endif
    " If the section number isn't empty insert two spaces before the title
    let l:fold_title = empty(l:section_num)
                     \ ? l:section_title
                     \ : l:section_num . ": " . l:section_title
  else
    " Get the section name, capitalizing its first letter and including
    " potential asterisks for starred sections (e.g. \chapter*{...}).
    let l:section_name = substitute(l:line, s:sections_regex, '\u\1\2', '')
    let l:fold_title = l:section_name . ": " . l:section_title
  endif

  " If I'm folding the preamble and the l:line contains a \documentclass, just
  " set l:fold_title to 'Preamble'.
  if g:LaTeXFolds_fold_preamble == 1 && l:line =~# '^\s*\\documentclass'
    let l:fold_title = "Preamble"
  endif

  return folds#FoldsTextFormat(l:fold_title)
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
