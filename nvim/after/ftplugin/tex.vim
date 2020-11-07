setlocal iskeyword-=:

setlocal spell
setlocal spelllang=en_us,it

setlocal errorformat=%f:%l:\ %m

" Use bash for its PIPESTATUS feature
setlocal shell=bash

let b:AutoPairs = {"(": ")", "[": "]", "{": "}", "`": "\"", "$": "$"}

let b:surround_{char2nr("e")} = "\\begin{\1environment: \1}\n\t\r\n\\end{\1\1}"
let b:surround_{char2nr("c")} = "\\\1command: \1{\r}"

if expand("%:e") ==# "tex"
  setlocal colorcolumn=80
  nmap <buffer> <silent> <C-t> :call tex#Compile()<CR>
  nmap <buffer> <silent> <LocalLeader>p :call tex#PdfOpen()<CR>
  nmap <buffer> <silent> <LocalLeader>f :call tex#SkimForwardSearch()<CR>
  nmap <buffer> <silent> <LocalLeader><LocalLeader> <plug>(vimtex-toc-open)
else
  setlocal formatoptions-=t
  " Don't highlight underscores in bright red
  syntax clear texOnlyMath
  " Enable spellcheck in comments only
  syntax spell notoplevel
endif
