let g:AutoPairs['$']='$'

setlocal shiftwidth=2 tabstop=2

nnoremap <buffer> <silent> <C-t> :call TeXCompile()<cr>
inoremap <buffer> <silent> <C-t> <esc>:call TeXCompile()<cr>a
nnoremap <buffer> <silent> <localleader>p :call PdfOpen()<cr>
nnoremap <buffer> <silent> <localleader>f :call SyncTeXForwardSearch()<cr>
