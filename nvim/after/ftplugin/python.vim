if !exists("current_compiler")
  compiler python3
endif

setlocal formatoptions-=r

nmap <buffer> <silent> <C-t> :make! <Bar> silent cc<CR>
