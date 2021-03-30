{ lib, colors }:

with lib;
let
  highlights =
    let
      spaceConcat = set:
        concatStringsSep " " (mapAttrsToList (n: v: "${n}=${v}") set);
    in
    concatStringsSep "\n" (mapAttrsToList
      (n: v: "  autocmd Colorscheme ${colors.colorscheme} hi ${n} ${spaceConcat v}")
      colors.highlights);
in
''
  local fn = vim.fn
  local cmd = vim.cmd
  local g = vim.g

  -- Automatically install Packer if it's not already installed
  local install_path = fn.stdpath('data') .. '/site/pack/packer/opt/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    cmd('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
  end

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

  cmd('silent! colorscheme ${colors.colorscheme}')

  g.terminal_color_0 = '${colors.terminal.color0}'
  g.terminal_color_1 = '${colors.terminal.color1}'
  g.terminal_color_2 = '${colors.terminal.color2}'
  g.terminal_color_3 = '${colors.terminal.color3}'
  g.terminal_color_4 = '${colors.terminal.color4}'
  g.terminal_color_5 = '${colors.terminal.color5}'
  g.terminal_color_6 = '${colors.terminal.color6}'
  g.terminal_color_7 = '${colors.terminal.color7}'

  require('mappings')
  require('options')
  require('plugins')
''
