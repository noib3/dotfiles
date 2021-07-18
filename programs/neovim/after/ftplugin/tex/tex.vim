if !exists('current_compiler')
  compiler pdflatex
endif

setlocal iskeyword-=:
setlocal spell
setlocal spelllang=en_us,it

let b:delimitMate_matchpairs = "(:),[:],{:},`:'"
let b:delimitMate_quotes = '$'
let b:surround_{char2nr('e')} = "\\begin{\1environment: \1}\n\t\r\n\\end{\1\1}"
let b:surround_{char2nr('c')} = "\\\1command: \1{\r}"

let g:LaTeXFolds_use_vimtex_section_numbers = 1

if expand('%:e') ==# 'tex'
  nmap <buffer> <silent> <C-t> <Cmd>make! <Bar> silent cc<CR>
  nmap <buffer> <silent> <LocalLeader><LocalLeader> <Plug>(vimtex-toc-open)
endif

augroup tex
  autocmd!
  autocmd BufRead *.tex silent execute
    \ '!nohup xdg-open "' . expand('%:p:r') . '.pdf" &>/dev/null &'
  autocmd BufUnload *.tex silent execute
    \ '!wmctrl -F -c "' . expand('%:p:r') . '.pdf" || true'
augroup END
