if !exists("current_compiler")
  compiler python3
endif

setlocal formatoptions-=r

nmap <buffer> <silent> <C-t> :make! <Bar> silent cc<CR>

let b:ale_linters = ["flake8", "pydocstyle", "pyls"]
let b:ale_fixers = ["autopep8", "isort"]
" let b:ale_python_flake8_options = ["--ignore=D101"]
