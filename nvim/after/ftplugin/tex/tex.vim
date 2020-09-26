" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Enable spell checking
setlocal spell
setlocal spelllang=en_us,it

" Display color column at 80 characters
setlocal cc=80

" Use bash for its PIPESTATUS feature
setlocal shell=bash

" Set the error format
setlocal errorformat=%f:%l:\ %m

" Autopair back quotes and dollar signs, don't pair upright single quotes
let b:AutoPairs = {'(': ')', '[': ']', '{': '}', '`': "'", '$': '$'}

" Only use these mappings if the file's extension is .tex (e.g. not in *.sty or
" *.cls files)
if expand('%:e') ==# 'tex'
  nmap <buffer> <silent> <C-t> :call tex#Compile()<CR>
  nmap <buffer> <silent> <LocalLeader>p :call tex#PdfOpen()<CR>
  nmap <buffer> <silent> <LocalLeader>f :call tex#SkimForwardSearch()<CR>
  nmap <buffer> <silent> <LocalLeader><LocalLeader> <plug>(vimtex-toc-open)
endif
