" Filename:   nvim/autoload/tex.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

" Compile the document and return pdflatex's exit code through PIPESTATUS. If
" it's not zero read the error file and jump to the first error.
function! tex#Compile()
  let errorfile='/tmp/nvim_tex.err'
  execute '!pdflatex -halt-on-error -file-line-error -synctex=1 ' . expand('%')
          \ . ' 2>&1 | tee ' . errorfile . '; exit ${PIPESTATUS[0]}'
  if v:shell_error
    execute 'silent cfile ' . errorfile
  endif
  execute 'silent !sudo rm ' . errorfile
endfunction

" Open the PDF file created by a TeX document
function! tex#PdfOpen()
  let filepath = expand('%:p:r') . '.pdf'
  if filereadable(filepath)
    execute 'silent !open ' . shellescape(filepath,1) . ' -g'
  else
    echohl ErrorMsg
    echomsg 'No pdf file "' . filepath . '"'
    echohl None
  endif
endfunction

" Close the PDF file created by a TeX document
function! tex#PdfClose(filepath, filename)
  if filereadable(a:filepath)
    let yabai_windows = json_decode(join(systemlist('yabai -m query --windows')))
    let Skim_windows = filter(yabai_windows, 'v:val.app=="Skim"')
    " if there is just one Skim window and its title matches the filename of
    " the file in the buffer, quit Skim
    if len(Skim_windows) == 1 && system("sed 's/\.pdf.*/.pdf/'", Skim_windows[0].title) == a:filename
      execute "silent !osascript -e \'quit app \"Skim\"\'"
    " if there are more Skim windows look for the one whose title matches the
    " filename of the file in the buffer and close it
    elseif len(Skim_windows) > 1
      for window in Skim_windows
        if system("sed 's/\.pdf.*/.pdf/'", window.title) == a:filename
          execute 'silent !yabai -m window ' . shellescape(window.id,1) . ' --close'
        endif
      endfor
    endif
  endif
endfunction

" Use Skim's displayline to jump from a line in a TeX document to its PDF output
function! tex#SkimForwardSearch()
  let filepath = expand('%:p:r') . '.pdf'
  if filereadable(filepath)
    execute 'silent !displayline ' . line('.') . ' ' . shellescape(filepath,1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "' . filepath . '"'
    echohl None
  endif
endfunction
