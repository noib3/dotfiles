g = vim.g

g.ale_disable_lsp = 1
g.ale_fix_on_save = 1

g.ale_linters = {
  python = {'flake8', 'pyls'}
}

g.ale_fixers = {
  ['*'] = {'remove_trailing_lines', 'trim_whitespace'},
  nix = {'nixpkgs-fmt'},
  python = {'autopep8', 'isort'},
}
