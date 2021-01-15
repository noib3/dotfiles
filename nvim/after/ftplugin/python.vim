if !exists("current_compiler")
  compiler python3
endif

setlocal formatoptions-=r

nmap <buffer> <silent> <C-t> :make! <Bar> silent cc<CR>

let b:ale_linters = ["flake8", "pyls"]
let b:ale_fixers = ["autopep8", "isort"]
