local keymap = vim.api.nvim_set_keymap

local context = require('plugins/config/snippets/context')

require'snippets'.snippets = {
  context = context;
}

keymap('i', '<Tab>', '<Cmd>lua return require"snippets".expand_or_advance(1)<CR>', {noremap = true})
keymap('i', '<S-Tab>', '<Cmd>lua return require"snippets".advance(-1)<CR>', {noremap = true})
