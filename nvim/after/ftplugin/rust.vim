if !exists("current_compiler")
  compiler cargo
endif

nmap <buffer> <silent> <C-t> :make! <Bar> silent cc<CR>
