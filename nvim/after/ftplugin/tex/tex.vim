" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Enable spell checking
setlocal spell
setlocal spelllang=en_us,it

" Make colon a word delimiter
setlocal iskeyword-=:

" Use bash for its PIPESTATUS feature
setlocal shell=bash

" Set the error format
setlocal errorformat=%f:%l:\ %m

" Autopair back quotes and dollar signs, don't pair upright single quotes
let b:AutoPairs = {'(': ')', '[': ']', '{': '}', '`': "'", '$': '$'}

" Only use these mappings in *.tex files
if expand('%:e') ==# 'tex'
  setlocal cc=80
  nmap <buffer> <silent> <C-t> :call tex#Compile()<CR>
  nmap <buffer> <silent> <LocalLeader>p :call tex#PdfOpen()<CR>
  nmap <buffer> <silent> <LocalLeader>f :call tex#SkimForwardSearch()<CR>
  nmap <buffer> <silent> <LocalLeader><LocalLeader> <plug>(vimtex-toc-open)
else
  setlocal cc=80,100
  setlocal formatoptions-=t
  " Clear the texOnlyMath syntax group to stop highlighting underscores in
  " bright red
  syntax clear texOnlyMath
  " Enable spellcheck in comments only
  syntax spell notoplevel
endif
