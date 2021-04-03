vim.cmd('autocmd BufEnter * lua require"completion".on_attach()')

require'completion'.addCompletionSource(
  'vimtex', require'plugins.config.completions.sources.vimtex'.complete_item)

vim.g.completion_chain_complete_list = {
  tex = {
    {complete_items = {'vimtex', 'lsp'}},
  };
}

vim.g.completion_enable_auto_paren = 1
