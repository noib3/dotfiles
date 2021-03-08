local g = vim.g
local cmd = vim.cmd

local M = {}

function M.patch_colors()
  g.terminal_color_0 = '#282828'
  g.terminal_color_1 = '#cc241d'
  g.terminal_color_2 = '#98971a'
  g.terminal_color_3 = '#d79921'
  g.terminal_color_4 = '#458588'
  g.terminal_color_5 = '#b16286'
  g.terminal_color_6 = '#689d6a'
  g.terminal_color_7 = '#ebdbb2'
  cmd('hi StatusLine guifg=NONE guibg=#83a598')
  cmd('hi SpellBad guifg=#cc241d gui=underline')
  cmd('hi SpellCap guifg=#fe8019 gui=NONE')
  cmd('hi VertSplit guifg=NONE guibg=#3c3836')
  cmd('hi htmlItalic guifg=#b16286 gui=italic')
  cmd('hi htmlBold guifg=#fe8019 gui=bold')
  cmd('hi texComment guifg=#928374')
  cmd('hi FzfBorder guifg=#a89984')
end

return M
