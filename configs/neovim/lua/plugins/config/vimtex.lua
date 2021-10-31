local g = vim.g
local fn = vim.fn

g.vimtex_compiler_enabled = 0
g.vimtex_format_enabled = 1
g.vimtex_syntax_conceal_disable = 1
g.vimtex_toc_show_preamble = 0

g.vimtex_toc_config = {
  indent_levels = 1,
  layers = {'content', 'include'},
  show_help = 0,
  split_width = 40,
  tocdepth = 6,
}

local uname = fn.substitute(fn.system('uname'), '\n', '', '')

if uname == 'Darwin' then
  g.vimtex_view_method = 'skim'
  g.vimtex_view_skim_reading_bar = 0
elseif uname == 'Linux' then
  g.vimtex_view_method = 'zathura'
end
