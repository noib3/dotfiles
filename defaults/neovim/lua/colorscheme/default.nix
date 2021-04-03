{ lib, colors }:

with lib;
let
  highlights =
    let
      spaceConcat = set:
        concatStringsSep " " (mapAttrsToList (n: v: "${n}=${v}") set);
    in
    concatStringsSep "\n" (mapAttrsToList
      (n: v: "autocmd Colorscheme ${colors.colorscheme} hi ${n} ${spaceConcat v}")
      colors.highlights);
in
''
  vim.api.nvim_exec([[
  augroup colorscheme
  autocmd!
  autocmd ColorScheme * hi Normal guibg=NONE
  autocmd ColorScheme * hi Comment gui=italic
  autocmd ColorScheme * hi goType gui=italic
  autocmd ColorScheme * hi! link texComment Comment
  ${highlights}
  augroup END
  ]], false)

  vim.cmd('colorscheme ${colors.colorscheme}')

  vim.g.terminal_color_0 = '${colors.terminal.color0}'
  vim.g.terminal_color_1 = '${colors.terminal.color1}'
  vim.g.terminal_color_2 = '${colors.terminal.color2}'
  vim.g.terminal_color_3 = '${colors.terminal.color3}'
  vim.g.terminal_color_4 = '${colors.terminal.color4}'
  vim.g.terminal_color_5 = '${colors.terminal.color5}'
  vim.g.terminal_color_6 = '${colors.terminal.color6}'
  vim.g.terminal_color_7 = '${colors.terminal.color7}'
''
