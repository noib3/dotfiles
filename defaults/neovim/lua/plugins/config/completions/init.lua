local add_source = require('completion').addCompletionSource
local sources = require('plugins/config/completions/sources')

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

g.completion_enable_auto_paren = 1
g.completion_enable_snippet = 'UltiSnips'
