local g = vim.g

g.ale_disable_lsp = 1
g.ale_fix_on_save = 1

g.ale_linters = {
  tex = {'proselint'},
}

g.ale_fixers = {
  ['*'] = {'remove_trailing_lines', 'trim_whitespace'},
  nix = {'nixpkgs-fmt'},

  -- isort doesn't work because ALE passes the '--filename' flag ([1]) which is
  -- not available in isort v5.6.4, which is the version currently listed on
  -- the 21.05 channel (and on the unstable channel too).

  -- TLDR: isort derivation on nixpkgs needs to be updated to a newer version
  -- for it to work

  python = {'isort', 'yapf'},
}

-- [1]: https://github.com/dense-analysis/ale/commit/d8f4e8b7081724c0b9ff2491dd68409b3da69b0f
