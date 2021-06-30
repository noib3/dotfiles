local add_source = require('completion').addCompletionSource
local sources = require('plugins/config/completions/sources')

local keymap = vim.api.nvim_set_keymap
local cmd = vim.cmd
local g = vim.g

cmd('autocmd BufEnter * lua require"completion".on_attach()')

add_source('vimtex', sources.vimtex.complete_item)

-- :help g:completion_chain_complete_list for a lot more customization options
g.completion_chain_complete_list = {
  default = {
    {complete_items = {'lsp', 'path'}},
  },

  tex = {
    {complete_items = {'lsp', 'vimtex'}},
  },
}
g.completion_confirm_key = ''
g.completion_enable_auto_paren = 1
g.completion_enable_snippet = 'UltiSnips'

keymap(
  'i', '<Tab>', [[pumvisible() ? '<C-n>' : '<Tab>']],
  {expr = true, noremap = true, silent = true}
)

keymap(
  'i', '<S-Tab>', [[pumvisible() ? '<C-p>' : '<Plug>delimitMateS-Tab']],
  {expr = true, silent = true}
)

keymap(
  'i', '<CR>',
  [[pumvisible() ? (complete_info()['selected'] != '-1' ? '<Plug>(completion_confirm_completion)' : '<C-E><Plug>delimitMateCR') : '<Plug>delimitMateCR']],
  {expr = true, silent = true}
)
