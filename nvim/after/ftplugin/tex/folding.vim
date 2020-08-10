" Filename:   nvim/after/ftplugin/tex/folding.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

" In the following comments and definitions a section is a generic sectioning
" command like \part{} or \subsection{}, not just a literal \section{}

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
    if dont_search_add_section
      call insert(fold_sections, [section, fold_level])
      let fold_level += 1
    else
      let i = 1
      while i < line('$')
        if getline(i) =~# '^\s*\\' . section . '{.*}\s*$'
          call insert(fold_sections, [section, fold_level])
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

function! LaTeXFoldsExpr(lnum)

  "
  let b:LaTeXFolds_fold_sections = s:ParseFoldSections()

  "
  let s:folded = '^\s*\\\(part\|chapter\|section\|subsection\|subsubsection\|end{document}\)'

  let this_line = getline(a:lnum)
  let next_line = getline(a:lnum + 1)

  " Check for normal lines first
  if this_line !~# s:folded
    " A blank line before \end{document} or before a fold level less then or equal to the
    " current one is left unfolded
    if this_line =~ '^\s*$' && next_line =~# s:folded
      if next_line =~# '^\s*\end{document}\s*$'
        return 0
      else
        for [section, level] in b:LaTeXFolds_fold_sections
          if next_line =~# '^\s*\\'.section.'{.*}\s*$'
            " I don't understand why I get the wanted result with <= instead of >=
            " Even < without the = works, it doesn't make sense
            if foldlevel(a:lnum - 1) <= level
              return level - 1
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


  for [section, level] in b:LaTeXFolds_fold_sections
    if this_line =~# '^\s*\\'.section.'{.*}\s*$'
      return ">".level
    endif
  endfor

  " return "="
endfunction

" }}}

" LaTeXFoldText {{{

function! LaTeXFoldText()
  return getline(v:foldstart)
endfunction

" }}}




" Taken from
"   https://github.com/petobens/dotfiles/blob/master/vim/ftplugin/tex/folding.vim

" " Initialization {{{

" if exists('b:loaded_mylatexfolding')
"     finish
" endif
" let b:loaded_mylatexfolding = 1

" " }}}

" " Set options {{{

" setlocal foldmethod=expr
" setlocal foldexpr=MyLatexFold_FoldLevel(v:lnum)
" setlocal foldtext=MyLatexFold_FoldText()

" if !exists('g:MyLatexFold_fold_preamble')
"     let g:MyLatexFold_fold_preamble = 1
" endif

" if !exists('g:MyLatexFold_fold_parts')
"     let g:MyLatexFold_fold_parts = [
"                 \ 'appendix',
"                 \ 'frontmatter',
"                 \ 'mainmatter',
"                 \ 'backmatter'
"                 \ ]
" endif

" if !exists('g:MyLatexFold_fold_sections')
"     let g:MyLatexFold_fold_sections = [
"                 \ 'part',
"                 \ 'chapter',
"                 \ 'section',
"                 \ 'subsection',
"                 \ 'subsubsection'
"                 \ ]
" endif

" if !exists('g:MyLatexFold_fold_envs')
"     let g:MyLatexFold_fold_envs = 1
" endif
" if !exists('g:MyLatexFold_folded_environments')
"     let g:MyLatexFold_folded_environments = [
"                \ 'abstract',
"                 \ 'frame'
"                 \ ]
" endif

" " }}}

" " MyLatexFold_FoldLevel helper functions {{{

" " This function parses the tex file to find the sections that are to be folded
" " and their levels, and then predefines the patterns for optimized folding.
" function! s:FoldSectionLevels()
"     " Initialize
"     let level = 1
"     let foldsections = []

"     " If we use two or more of the *matter commands, we need one more foldlevel
"     let nparts = 0
"     for part in g:MyLatexFold_fold_parts
"         let i = 1
"         while i < line('$')
"             if getline(i) =~ '^\s*\\' . part . '\>'
"                 let nparts += 1
"                 break
"             endif
"             let i += 1
"         endwhile
"         if nparts > 1
"             let level = 2
"             break
"         endif
"     endfor

"     " Combine sections and levels, but ignore unused section commands:  If we
"     " don't use the part command, then chapter should have the highest
"     " level.  If we don't use the chapter command, then section should be the
"     " highest level.  And so on.
"     let ignore = 1
"     for part in g:MyLatexFold_fold_sections
"         " For each part, check if it is used in the file.  We start adding the
"         " part patterns to the fold sections array whenever we find one.
"         let partpattern = '^\s*\(\\\|% Fake\)' . part . '\>'
"         if ignore
"             let i = 1
"             while i < line('$')
"                 if getline(i) =~# partpattern
"                     call insert(foldsections, [partpattern, level])
"                     let level += 1
"                     let ignore = 0
"                     break
"                 endif
"                 let i += 1
"             endwhile
"         else
"             call insert(foldsections, [partpattern, level])
"             let level += 1
"         endif
"     endfor

"     return foldsections
" endfunction

" " }}}

" " MyLatexFold_FoldLevel {{{

" " Parse file to dynamically set the sectioning fold levels
" let b:MyLatexFold_FoldSections = s:FoldSectionLevels()

" " Optimize by predefine common patterns
" let s:foldparts = '^\s*\\\%(' . join(g:MyLatexFold_fold_parts, '\|') . '\)'
" let s:folded = '\(% Fake\|\\\(document\|begin\|end\|'
"             \ . 'front\|main\|back\|app\|sub\|section\|chapter\|part\)\)'

" " Fold certain selected environments
" let s:notbslash = '\%(\\\@<!\%(\\\\\)*\)\@<='
" let s:notcomment = '\%(\%(\\\@<!\%(\\\\\)*\)\@<=%.*\)\@<!'
" let s:envbeginpattern = s:notcomment . s:notbslash .
"             \ '\\begin\s*{\('. join(g:MyLatexFold_folded_environments, '\|') .'\)}'
" let s:envendpattern = s:notcomment . s:notbslash .
"             \ '\\end\s*{\('. join(g:MyLatexFold_folded_environments, '\|') . '\)}'

" function! MyLatexFold_FoldLevel(lnum)
"     " Check for normal lines first (optimization)
"     let line  = getline(a:lnum)
"     if line !~ s:folded
"         return '='
"     endif

"     " Fold preamble
"     if g:MyLatexFold_fold_preamble == 1
"         if line =~# s:notcomment . s:notbslash . '\s*\\documentclass'
"             return '>1'
"         elseif line =~# s:notcomment . s:notbslash .
"                     \ '\s*\\begin\s*{\s*document\s*}'
"             return '0'
"         endif
"     endif

"     " Fold parts (\frontmatter, \mainmatter, \backmatter, and \appendix)
"     if line =~# s:foldparts
"         return '>1'
"     endif

"     " Fold chapters and sections
"     for [part, level] in b:MyLatexFold_FoldSections
"         if line =~# part
"             return '>' . level
"         endif
"     endfor

"     " Never fold \end{document}
"     if line =~# '^\s*\\end{document}'
"         return 0
"     endif

"     " Fold environments
"     if g:MyLatexFold_fold_envs == 1
"         if line =~# s:envbeginpattern
"             return 'a1'
"         elseif line =~# s:envendpattern
"             return 's1'
"         endif
"     endif

"     " Return foldlevel of previous line
"     return '='
" endfunction

" " }}}

" " MyLatexFold_FoldText helper functions {{{

" function! s:CaptionFrame(line)
"     " Test simple variants first
"     let caption1 = matchstr(a:line,'\\begin\*\?{.*}{\zs.\+\ze}')
"     let caption2 = matchstr(a:line,'\\begin\*\?{.*}{\zs.\+')

"     if len(caption1) > 0
"         return caption1
"     elseif len(caption2) > 0
"         return caption2
"     else
"         let i = v:foldstart
"         while i <= v:foldend
"             if getline(i) =~# '^\s*\\frametitle'
"                 return matchstr(getline(i),
"                             \ '^\s*\\frametitle\(\[.*\]\)\?{\zs.\+')
"             end
"             let i += 1
"         endwhile

"         return ''
"     endif
" endfunction

" " }}}

" " MyLatexFold_FoldText {{{

" function! MyLatexFold_FoldText()
"     " Initialize
"     let line = getline(v:foldstart)
"     let nlines = v:foldend - v:foldstart + 1
"     let level = ''
"     let title = 'Not defined'

"     " Fold level and number of lines
" 	let level = '+-' . repeat('-', v:foldlevel-1) . ' '
"     let alignlnr = repeat(' ', 6-(v:foldlevel-1)-len(nlines))
"     let lineinfo = nlines . ' lines: '

"     " Preamble
"     if line =~# '\s*\\documentclass'
"         let title = 'Preamble'
"     endif

"     " Parts, sections and fakesections
"     let sections = '\(\(sub\)*section\|part\|chapter\)'
"     let secpat1 = '^\s*\\' . sections . '\*\?\s*{'
"     let secpat2 = '^\s*\\' . sections . '\*\?\s*\['
"     if line =~# '\\frontmatter'
"         let title = 'Frontmatter'
"     elseif line =~# '\\mainmatter'
"         let title = 'Mainmatter'
"     elseif line =~# '\\backmatter'
"         let title = 'Backmatter'
"     elseif line =~# '\\appendix'
"         let title = 'Appendix'
"     elseif line =~ secpat1 . '.*}'
"         let title =  line
"     elseif line =~ secpat1
"         let title = line
"     elseif line =~ secpat2 . '.*\]'
"         let title = line
"     elseif line =~ secpat2
"         let title = line
"     elseif line =~ 'Fake' . sections . ':'
"         let title =  matchstr(line,'Fake' . sections . ':\s*\zs.*')
"     elseif line =~ 'Fake' . sections
"         let title =  matchstr(line, 'Fake' . sections)
"     endif

"     " Environments
"     if line =~# '\\begin'
"         " Capture environment name
"         let env = matchstr(line,'\\begin\*\?{\zs\w*\*\?\ze}')
"         if env ==# 'abstract'
"             let title = 'Abstract'
"         elseif env ==# 'frame'
"             let caption = s:CaptionFrame(line)
"             let title = 'Frame - ' . substitute(caption, '}\s*$', '','')
"         endif
"     endif

"     return level . alignlnr . lineinfo . title . ' '
" endfunction

" " }}}
