local g   = vim.g
local cmd = vim.cmd

local M = { }

function M.patch_colors()
  g.terminal_color_0 = '#1a1a1a'
  g.terminal_color_1 = '#ac4142'
  g.terminal_color_2 = '#b4c973'
  g.terminal_color_3 = '#e5b567'
  g.terminal_color_4 = '#6c99bb'
  g.terminal_color_5 = '#b05279'
  g.terminal_color_6 = '#9e86c8'
  g.terminal_color_7 = '#d6d6d6'
  cmd('hi Visual     guifg=#d6d6d6 guibg=#5a647e')
  cmd('hi SpellBad   guifg=#ac4142 gui=underline')
  cmd('hi SpellCap   guifg=#e87d3e gui=NONE')
  cmd('hi VertSplit  guifg=NONE    guibg=#393939')
  cmd('hi htmlItalic guifg=#9e86c8 gui=italic')
  cmd('hi htmlBold   guifg=#e87d3e gui=bold')
  cmd('hi FzfBorder  guifg=#797979')
end

return M
