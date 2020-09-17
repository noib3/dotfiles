" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" Formatting
setlocal formatoptions-=r

" Display vertical columns at 80 and 100 characters
setlocal cc=80,100

" Compile the document
nmap <buffer> <silent> <C-t> :call PyCompile()<CR>

function! PyCompile()
  execute '!python3 ' . expand('%')
endfunction
