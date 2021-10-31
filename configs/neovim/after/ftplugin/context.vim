setlocal spelllang=en_us,it
setlocal formatoptions-=ro

nmap <buffer> <silent> <C-t> <Cmd>!context --purge ./%<CR>
" nmap <buffer> <silent> <C-t> <Cmd>ConTeXt<CR>
nmap <buffer> <silent> <LocalLeader>lv <Cmd>call <SID>open()<CR>

function! s:open()
  " Try to open the compiled PDF file if it's not already opened
  let l:pdf_filename = expand('%:p:r') . '.pdf'
  let l:pdf_is_opened = 0
  let l:opened_windows = systemlist('wmctrl -l')
  for window in l:opened_windows
    if window =~ l:pdf_filename
      let l:pdf_is_opened = 1
      break
    endif
  endfor
  if !l:pdf_is_opened
    silent execute printf('!nohup xdg-open "%s" &>/dev/null &', l:pdf_filename)
  endif
endfunction

function! s:close()
  " Close the compiled PDF file
  let l:pdf_filename = expand('%:p:r') . '.pdf'
  silent execute printf('!wmctrl -F -c "%s"', l:pdf_filename)
endfunction

augroup tex
  autocmd!
  autocmd BufUnload *.tex call <SID>close()
augroup END
