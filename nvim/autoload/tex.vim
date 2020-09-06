" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

function! tex#Compile() " {{{1
  " Compile the document and return pdflatex's exit code through PIPESTATUS. If
  " it's not zero read the error file and jump to the first error.
  " Unfortunately pdflatex doesn't pass the errors' column numbers to quickfix,
  " so the best we can do if there's an error is to jump to the corresponding
  " line.
  let errorfile='/tmp/nvim_tex.err'
  execute '!pdflatex -halt-on-error -file-line-error -synctex=1 ' . expand('%')
          \ . ' 2>&1 | tee ' . errorfile . '; exit ${PIPESTATUS[0]}'
  if v:shell_error
    execute 'silent cfile ' . errorfile
  endif
  execute 'silent !sudo rm ' . errorfile
endfunction " }}}1

function! tex#PdfOpen() " {{{1
  " Open the PDF file created by a TeX document
  let filepath = expand('%:p:r') . '.pdf'
  if filereadable(filepath)
    execute 'silent !open ' . shellescape(filepath,1) . ' -g'
  else
    echohl ErrorMsg
    echomsg 'No pdf file "' . filepath . '"'
    echohl None
  endif
endfunction " }}}1

function! tex#PdfClose(filepath, filename) " {{{1
  " Close the PDF file created by a TeX document. It only works with yabai +
  " Skim.
  if filereadable(a:filepath)
    let yabai_windows = json_decode(join(systemlist('yabai -m query --windows')))
    let Skim_windows = filter(yabai_windows, 'v:val.app=="Skim"')
    " If there is just one Skim window and its title matches the filename of
    " the file in the buffer, quit Skim.
    if len(Skim_windows) == 1
       \ && substitute(Skim_windows[0].title, '\.pdf.*', '.pdf', '') == a:filename
      execute "silent !osascript -e \'quit app \"Skim\"\'"
    " If there are more Skim windows look for the one whose title matches the
    " filename of the file in the buffer and close it.
    elseif len(Skim_windows) > 1
      for window in Skim_windows
        if substitute(window.title, '\.pdf.*', '.pdf', '') == a:filename
          execute 'silent !yabai -m window ' . shellescape(window.id,1) . ' --close'
        endif
      endfor
    endif
  endif
endfunction " }}}1

function! tex#SkimForwardSearch() " {{{1
  " Use Skim's displayline to jump from a line in a TeX document to its PDF
  " output.
  let filepath = expand('%:p:r') . '.pdf'
  if filereadable(filepath)
    execute 'silent !displayline ' . line('.') . ' ' . shellescape(filepath,1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "' . filepath . '"'
    echohl None
  endif
endfunction " }}}1

" vim:fdm=marker
