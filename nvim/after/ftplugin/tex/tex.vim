" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Use two spaces for indentation
setlocal tabstop=2 softtabstop=2 shiftwidth=2

" Enable spell checking
setlocal spell
setlocal spelllang=en_us,it

if expand('%:e') ==# 'tex'
  " Display a single color column at 80 characters for *.tex files
  setlocal cc=80
else
  setlocal formatoptions-=t
  " Display two color columns at 80 and 100 characters for all other extensions
  " (e.g. *.sty or *.cls)
  setlocal cc=80,100
  " Clear the texOnlyMath syntax group to stop highlighting underscores in
  " bright red
  syntax clear texOnlyMath
  " Enable spellcheck in comments only
  syntax spell notoplevel
endif

" Use bash for its PIPESTATUS feature
setlocal shell=bash

" Set the error format
setlocal errorformat=%f:%l:\ %m

" Autopair back quotes and dollar signs, don't pair upright single quotes
let b:AutoPairs = {'(': ')', '[': ']', '{': '}', '`': "'", '$': '$'}

" Only use these mappings in *.tex files
if expand('%:e') ==# 'tex'
  nmap <buffer> <silent> <C-t> :call tex#Compile()<CR>
  nmap <buffer> <silent> <LocalLeader>p :call tex#PdfOpen()<CR>
  nmap <buffer> <silent> <LocalLeader>f :call tex#SkimForwardSearch()<CR>
  nmap <buffer> <silent> <LocalLeader><LocalLeader> <plug>(vimtex-toc-open)
endif
