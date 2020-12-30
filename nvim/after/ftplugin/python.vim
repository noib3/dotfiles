setlocal formatoptions-=r
setlocal shell=bash " Using bash for its PIPESTATUS feature
setlocal shiftwidth=2
setlocal tabstop=2

nmap <buffer> <silent> <C-t> :call python#Run()<CR>
" nmap <buffer> <silent> <C-t> :!%<CR>
