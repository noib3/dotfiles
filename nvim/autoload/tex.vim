" Filename:   tex.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

" Open the PDF file created by a TeX document
function! tex#PDFOpen()
  let filepath = expand('%:p:r').'.pdf'
  if filereadable(filepath)
    execute 'silent !open '.shellescape(filepath,1).' -g'
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filepath.'"'
    echohl None
  endif
endfunction

" Close the PDF file created by a TeX document
function! tex#PDFClose(filepath, filename)
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
          execute "silent !yabai -m window ".shellescape(window.id,1)." --close"
        endif
      endfor
    endif
  endif
endfunction

" Use Skim's displayline to jump from a line in a TeX document to its PDF output
function! tex#SkimForwardSearch()
  let filepath = expand('%:p:r').'.pdf'
  if filereadable(filepath)
    execute "silent !/Applications/Skim.app/Contents/SharedSupport/displayline ".line(".")." ".shellescape(filepath,1)
  else
    echohl ErrorMsg
    echomsg 'No pdf file "'.filepath.'"'
    echohl None
  endif
endfunction
