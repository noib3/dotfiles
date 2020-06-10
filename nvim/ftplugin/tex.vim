" Open the pdf file on entry and close it on exit
" actually I need to put this back into an autocmd if I open multiple buffers
" call tex#pdf_open()
autocmd BufRead    *.tex call tex#pdf_open()
autocmd BufUnload  *.tex call tex#pdf_close()

" Use two spaces for the indentation
setlocal shiftwidth=2 tabstop=2

" Set the make program and use a file-line error format
set makeprg=pdflatex\ -halt-on-error\ -file-line-error\ -synctex=1\ %
set makeef=/var/tmp/ef.txt
set errorformat=%A%f:%l:\ %m,%C%m

" Automatically insert a matching dollar sign for inline math
let g:AutoPairs['$']='$'

" Mappings to compile the document, open the pdf file and forward search from the tex to the pdf
nmap <buffer> <silent> <C-t> :make<cr>
imap <buffer> <silent> <C-t> <esc>:make<cr>a
" nmap <buffer> <silent> <C-t> :execute "!pdflatex -halt-on-error -file-line-error -synctex=1 %"<cr>
nmap <buffer> <silent> <localleader>p :call tex#pdf_open()<cr>
nmap <buffer> <silent> <localleader>f :call tex#Skim_forward_search()<cr>
