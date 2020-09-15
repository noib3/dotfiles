" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
setlocal formatoptions-=t

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Enable spell checking
setlocal spell
setlocal spelllang=en_us,it

" Use bash for its PIPESTATUS feature
setlocal shell=bash

" setlocal the error format
setlocal errorformat=%f:%l:\ %m

" Autopair back quotes and dollar signs, don't pair upright single quotes
let b:AutoPairs = {'(': ')', '[': ']', '{': '}', '`': "'", '$': '$'}

" Compile the document, open the PDF file and forward search from nvim to Skim
nmap <buffer> <silent> <C-t> :call tex#Compile()<CR>
nmap <buffer> <silent> <LocalLeader>p :call tex#PdfOpen()<CR>
nmap <buffer> <silent> <LocalLeader>f :call tex#SkimForwardSearch()<CR>

" Open vimtex's ToC window
nmap <silent> <LocalLeader><LocalLeader> <plug>(vimtex-toc-open)