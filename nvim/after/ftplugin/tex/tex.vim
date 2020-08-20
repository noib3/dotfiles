" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
set formatoptions-=t

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Enable spell checking
setlocal spell
setlocal spelllang=en_us,it

" Use bash for its PIPESTATUS feature
setlocal shell=bash

" Set the error format
setlocal errorformat=%f:%l:\ %m

" Autopair dollar signs
let g:AutoPairs['$']='$'

" Compile the document, open the PDF file and forward search from nvim to Skim
nmap <buffer> <silent> <C-t> :call tex#Compile()<CR>
nmap <buffer> <silent> <localleader>p :call tex#PdfOpen()<CR>
nmap <buffer> <silent> <localleader>f :call tex#SkimForwardSearch()<CR>

" Open vimtex's ToC window
nmap <silent> <Leader><Leader> <plug>(vimtex-toc-open)

" Autoinsert '\item ' on the next line if the current line has '\item' in it
" Inspired by the following Stack Overflow answer
"   https://stackoverflow.com/a/2554770/10786411:
imap <buffer> <expr> <CR> "\r".tex#AutoInsertItem()
nmap <buffer> <expr> o "o".tex#AutoInsertItem()
nmap <buffer> <expr> O "O".tex#AutoInsertItem()
