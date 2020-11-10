setlocal iskeyword-=:

setlocal spell
setlocal spelllang=en_us,it

setlocal errorformat=%f:%l:\ %m

" Use bash for its PIPESTATUS feature
setlocal shell=bash

let g:LaTeXFolds_use_vimtex_section_numbers = 1

let b:AutoPairs = {"(": ")", "[": "]", "{": "}", "`": "\"", "$": "$"}

let b:surround_{char2nr("e")} = "\\begin{\1environment: \1}\n\t\r\n\\end{\1\1}"
let b:surround_{char2nr("c")} = "\\\1command: \1{\r}"

if expand("%:e") ==# "tex"
  VimtexView
  nmap <buffer> <silent> <C-t> :call tex#Compile()<CR>
  nmap <buffer> <silent> <LocalLeader><LocalLeader> <plug>(vimtex-toc-open)
endif

augroup tex
  autocmd!
  autocmd BufUnload *.tex call tex#PdfClose(expand("<afile>:p:r") . ".pdf")
augroup END
