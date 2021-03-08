local g = vim.g

g.vimtex_compiler_enabled = 0
g.vimtex_format_enabled = 1
g.vimtex_syntax_conceal_default = 0
g.vimtex_toc_show_preamble = 0

g.vimtex_toc_config = {
  indent_levels = 1,
  layers = {'content', 'include'},
  show_help = 0,
  split_width = 40,
  tocdepth = 6,
}

g.vimtex_view_method = 'skim'
g.vimtex_view_skim_reading_bar = 0
