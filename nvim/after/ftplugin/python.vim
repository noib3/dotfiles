if !exists("current_compiler")
  compiler python3
endif

setlocal formatoptions-=r
setlocal shiftwidth=2
setlocal tabstop=2

nmap <buffer> <silent> <C-t> :make! <Bar> silent cc<CR>

let b:ale_linters = ['flake8', 'pydocstyle', 'pyls']
let b:ale_fixers = ['black', 'isort']
