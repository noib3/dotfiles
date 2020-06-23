" Compile a LaTeX document
" function! tex#compile_LaTeX()
"   let filepath = expand('%:p')
"   execute "!cd $(dirname ".shellescape(filepath,1).") && pdflatex -synctex=1 ".shellescape(filepath,1)
" endfunction

" Open the pdf file created by a TeX document
function! tex#pdf_open()
  let filepath = expand('%:p:r').'.pdf'
  if filereadable(filepath)
    execute 'silent !open '.shellescape(filepath,1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filepath.'"'
    echohl None
  endif
endfunction

" Close the pdf file created by a TeX document
function! tex#pdf_close()
  let filepath = expand('%:p:r').'.pdf'
  let filename = expand('%:t:r').'.pdf'
  if filereadable(filepath)
    let yabai_windows = json_decode(join(systemlist('yabai -m query --windows')))
    let Skim_windows = filter(yabai_windows, 'v:val.app=="Skim"')
    " if there is just one Skim window and its title matches the filename of
    " the file in the buffer, quit Skim
    if len(Skim_windows) == 1 && system("sed 's/\.pdf.*/.pdf/'", Skim_windows[0].title) == filename
      execute "silent !osascript -e \'quit app \"Skim\"\'"
    " if there are more Skim windows look for the one whose title matches the
    " filename of the file in the buffer and close it
    elseif len(Skim_windows) > 1
      for window in Skim_windows
        if system("sed 's/\.pdf.*/.pdf/'", window.title) == filename
          execute "silent !yabai -m window ".shellescape(window.id,1)." --close"
        endif
      endfor
    endif
  endif
endfunction

" Use Skim's displayline to jump from a line in a tex document to its pdf output
function! tex#Skim_forward_search()
  let filepath = expand('%:p:r').'.pdf'
  if filereadable(filepath)
    execute "silent !/Applications/Skim.app/Contents/SharedSupport/displayline ".line(".")." ".shellescape(filepath,1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filepath.'"'
    echohl None
  endif
endfunction
