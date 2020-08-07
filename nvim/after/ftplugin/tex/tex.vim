" Filename:   nvim/after/ftplugin/tex/tex.vim
" Github:     https://github.com/n0ibe/macOS-dotfiles
" Maintainer: Riccardo Mazzarini

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Use bash for its PIPESTATUS feature
setlocal shell=bash

" Set the error format
setlocal errorformat=%f:%l:\ %m

" Autopair dollar signs
let g:AutoPairs['$']='$'

" Mappings to compile the document, open the PDF file and forward search from the tex to the PDF
nmap <buffer> <silent> <C-t> :call Make()<CR>
nmap <buffer> <silent> <localleader>p :call tex#PDFOpen()<cr>
nmap <buffer> <silent> <localleader>f :call tex#SkimForwardSearch()<cr>

" Compile the document and return pdflatex's exit code through PIPESTATUS
" If it's not zero read the error file and jump to the first error
function! Make()
  let errorfile='/tmp/nvim_tex.err'
  execute '!pdflatex -halt-on-error -file-line-error -synctex=1 '.expand('%').' 2>&1 | tee '.errorfile.'; exit ${PIPESTATUS[0]}'
  if v:shell_error
    execute 'silent cfile '.errorfile
  endif
  execute 'silent !sudo rm '.errorfile
endfunction
