{ lib ? import <nixpkgs/lib>, colors }:

let
  highlights = with lib;
    let
      spaceConcat = set:
        concatStringsSep " " (mapAttrsToList (n: v: "${n}=${v}") set);
    in
    concatStringsSep "\n" (
      mapAttrsToList
        (n: v: "autocmd Colorscheme ${colors.colorscheme} hi ${n} ${spaceConcat v}")
        colors.highlights
    );
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

  vim.g.terminal_color_0 = '${colors.terminal.black}'
  vim.g.terminal_color_1 = '${colors.terminal.red}'
  vim.g.terminal_color_2 = '${colors.terminal.green}'
  vim.g.terminal_color_3 = '${colors.terminal.yellow}'
  vim.g.terminal_color_4 = '${colors.terminal.blue}'
  vim.g.terminal_color_5 = '${colors.terminal.magenta}'
  vim.g.terminal_color_6 = '${colors.terminal.cyan}'
  vim.g.terminal_color_7 = '${colors.terminal.white}'
''
