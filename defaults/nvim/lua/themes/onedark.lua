local g = vim.g
local cmd = vim.cmd

local M = {}

function M.patch_colors()
  g.terminal_color_0 = '#282c34'
  g.terminal_color_1 = '#e06c75'
  g.terminal_color_2 = '#98c379'
  g.terminal_color_3 = '#e5c07b'
  g.terminal_color_4 = '#61afef'
  g.terminal_color_5 = '#c678dd'
  g.terminal_color_6 = '#56b6c2'
  g.terminal_color_7 = '#abb2bf'
  cmd('hi SpellBad guifg=#e06c75 gui=underline')
  cmd('hi SpellCap guifg=#d19a66 gui=NONE')
  cmd('hi VertSplit guifg=NONE guibg=#3e4452')
  cmd('hi LspReferenceRead guibg=#3e4452')
  cmd('hi LspReferenceText guibg=#3e4452')
  cmd('hi LspReferenceWrite guibg=#3e4452')
  cmd('hi Whitespace guifg=#5c6370')
  cmd('hi FzfBorder guifg=#5c6073')
end

return M
