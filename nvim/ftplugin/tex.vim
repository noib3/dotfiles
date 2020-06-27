" Filename:   tex.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Set the make program and use a file-line error format
let &makeprg='pdflatex -halt-on-error -file-line-error -synctex=1 %'
let &errorformat='%f:%l: %m'

" Automatically insert a matching dollar sign for inline math
let g:AutoPairs['$']='$'

" Mappings to compile the document, open the PDF file and forward search from the tex to the PDF
nmap <buffer> <silent> <C-t> :call Make()<CR>
nmap <buffer> <silent> <localleader>p :call tex#PDFOpen()<cr>
nmap <buffer> <silent> <localleader>f :call tex#Skim_forward_search()<cr>

" Compile a LaTeX document
function! Make()
  let [_, line, col, _, _] = getcurpos()
  make
  " if make! exit code is 0
  " call cursor(line, col)
  " else
  silent cn
endfunction
