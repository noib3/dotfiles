" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
setlocal formatoptions-=r

" Display vertical columns at 80 and 100 characters
setlocal cc=80,100

" Compile the document
nmap <buffer> <silent> <C-t> :call PyComp()<CR>
" nmap <buffer> <silent> <C-t> :!python3 % <CR>

function! PyComp()
  execute '!python3 ' . expand('%')
endfunction
