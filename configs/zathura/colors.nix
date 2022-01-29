{ colorscheme, palette }:

let
  hexlib = import ../../palettes/hexlib.nix;

  c = {
    "afterglow" = {
      inputbar.fg = palette.normal.white;
      highlight.bg = palette.normal.cyan;
    };
    "gruvbox".inputbar.fg = hexlib.scale 1.3 palette.bright.white;
    "nord".inputbar.fg = hexlib.scale 1.3 palette.bright.white;
    "onedark" = {
      inputbar.fg = palette.normal.white;
      highlight.bg = palette.normal.yellow;
    };
    "tokyonight".inputbar.fg = hexlib.scale 1.3 palette.bright.white;
  };
in
{
  default = {
    bg = palette.normal.black;
    fg = palette.normal.white;
  };

  inputbar = {
    bg = palette.bright.black;
    fg = c.${colorscheme}.inputbar.fg or palette.bright.white;
  };

  highlight.bg = c.${colorscheme}.highlight.bg or palette.normal.blue;
}
