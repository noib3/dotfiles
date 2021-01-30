let g:ale_disable_lsp = 1
let g:ale_fix_on_save = 1
let g:ale_linters = {
  \ 'python': ['flake8', 'pyls']
  \ }
let g:ale_fixers = {
  \ '*': ['remove_trailing_lines', 'trim_whitespace'],
  \ 'python': ['autopep8', 'isort'],
  \ }
