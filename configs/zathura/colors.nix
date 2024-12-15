{
  config,
  colorscheme,
  palette,
}:

let
  inherit (config.lib.mine) hex;
  c = {
    "afterglow" = {
      inputbar.fg = palette.normal.white;
      highlight.bg = palette.normal.cyan;
    };
    "gruvbox".inputbar.fg = hex.scale 1.3 palette.bright.white;
    "tokyonight".inputbar.fg = hex.scale 1.3 palette.bright.white;
  };
in
{
  default = {
    bg = palette.primary.background or palette.normal.black;
    fg = palette.primary.foreground or palette.normal.white;
  };

  inputbar = {
    bg = palette.bright.black;
    fg = c.${colorscheme}.inputbar.fg or palette.bright.white;
  };

  highlight.bg = c.${colorscheme}.highlight.bg or palette.normal.blue;
}
