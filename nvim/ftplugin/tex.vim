let g:AutoPairs['$']='$'

setlocal shiftwidth=2 tabstop=2

nnoremap <buffer> <silent> <C-t> :call latex#compile()<cr>
inoremap <buffer> <silent> <C-t> <esc>:call latex#compile()<cr>a
nnoremap <buffer> <silent> <localleader>p :call PdfOpen()<cr>
nnoremap <buffer> <silent> <localleader>f :call SyncTeXForwardSearch()<cr>
